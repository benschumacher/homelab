# printserver

Raspberry Pi 3 running CUPS print server and `rtl_tcp` for SDR.

- **Hostname**: `printserver`
- **IP**: `192.168.11.196` (static, via DHCP reservation)
- **Interface**: `wlan0`
- **OS**: Raspberry Pi OS Lite 64-bit (Debian Bookworm)
- **Hardware**: Raspberry Pi 3B+
- **Printer**: HP LaserJet 1022n (network)
- **SDR**: RTL-SDR dongle via `rtl_tcp` (built from source, memory leak fix)

---

## Rebuild Runbook

### 1. Flash & First Boot

Flash **Raspberry Pi OS Lite (64-bit)** to a new SD card using `rpi-imager` or `dd`.

In `rpi-imager` advanced options (or via `raspi-config` post-boot):
- Hostname: `printserver`
- Enable SSH
- Set locale/timezone
- Configure WiFi

On first boot, verify SSH access:
```sh
ssh pi@printserver.local
```

### 2. System Basics

```sh
sudo apt update && sudo apt upgrade -y
sudo raspi-config   # verify hostname, locale, timezone, WiFi
```

Update `/etc/fstab` to add `noatime` to the root mount (reduces SD card writes):
```
PARTUUID=<uuid>-02  /  ext4  defaults,noatime  0  1
```

Add tmpfs mounts for high-write paths:
```
tmpfs  /tmp      tmpfs  defaults,noatime,nosuid,size=100m  0  0
tmpfs  /var/log  tmpfs  defaults,noatime,nosuid,size=50m   0  0
```

Install log2ram (keeps logs in RAM, syncs periodically):
```sh
sudo apt install log2ram
```

### 3. Install Packages

```sh
sudo apt install -y \
    cups \
    cups-browsed \
    printer-driver-foo2zjs \
    mosquitto-clients \
    git \
    cmake \
    build-essential \
    libusb-1.0-0-dev \
    python3-rpi.gpio \
    tailscale
```

Add `pi` to the `lpadmin` group for CUPS administration:
```sh
sudo usermod -aG lpadmin pi
```

### 4. Tailscale

```sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### 5. Clone Repos & Set Up homeskel

```sh
mkdir -p ~/src/repos
cd ~/src/repos
git clone git@github.com:benschumacher/homeskel.git
cd homeskel && ./install.sh   # symlinks dotfiles into ~/
```

Clone the homelab repo for configs:
```sh
cd ~/src/repos
git clone git@github.com:benschumacher/homelab.git
```

### 6. Build rtl-sdr from Source

`rtl_tcp` is built from a fork that includes a memory leak fix (PR pending upstream on
the semi-abandoned `pinkavaj/rtl-sdr`):

```sh
cd ~/src/repos
git clone https://github.com/pinkavaj/rtl-sdr.git
cd rtl-sdr
git remote add upstream git@github.com:benschumacher/rtl-sdr.git
git fetch upstream
git checkout -b rtltcp_memory_leak upstream/rtltcp_memory_leak

mkdir build && cd build
cmake ..
make -j4
sudo make install
sudo ldconfig
```

### 7. CUPS Configuration

Copy CUPS config from the homelab repo:
```sh
sudo cp -a ~/src/repos/homelab/hosts/printserver/etc/cups/cupsd.conf /etc/cups/
sudo cp -a ~/src/repos/homelab/hosts/printserver/etc/cups/printers.conf /etc/cups/
sudo cp -a ~/src/repos/homelab/hosts/printserver/etc/cups/ppd/ /etc/cups/

sudo systemctl enable --now cups
```

Verify CUPS is accessible at `http://printserver.local:631`.

### 8. rtl_tcp Service

Copy the systemd unit:
```sh
sudo cp ~/src/repos/homelab/hosts/printserver/etc/systemd/system/rtl_tcp.service \
    /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now rtl_tcp
```

> **Note**: The service hardcodes IP `192.168.11.196` and interface `wlan0`. Update
> `/etc/systemd/system/rtl_tcp.service` if either changes.

### 9. Scripts & Credentials

Copy monitoring scripts from the homelab repo:
```sh
mkdir -p ~/bin
cp ~/src/repos/homelab/hosts/printserver/home/pi/bin/* ~/bin/
chmod +x ~/bin/*.sh ~/bin/*.py
```

The `under_voltage_check.sh` script publishes to MQTT and requires credentials.
Create `~/.config/printserver/env` (not in repo):
```sh
mkdir -p ~/.config/printserver
cat > ~/.config/printserver/env <<'EOF'
MQTT_USER=your_mqtt_username
MQTT_PASSWORD=your_mqtt_password
EOF
chmod 600 ~/.config/printserver/env
```

Deploy the script from the template:
```sh
source ~/.config/printserver/env
envsubst < ~/src/repos/homelab/hosts/printserver/home/pi/bin/under_voltage_check.sh.template \
    > ~/bin/under_voltage_check.sh
chmod +x ~/bin/under_voltage_check.sh
```

### 10. Crontab

```sh
crontab -e
```

Add:
```
PATH=/bin:/usr/bin:/home/pi/bin
*/60 * * * * under_voltage_check.sh
```

### 11. Verify

```sh
# CUPS
sudo systemctl status cups

# rtl_tcp
sudo systemctl status rtl_tcp
journalctl -u rtl_tcp -n 20

# SDR connectivity (from another host)
nc -zv printserver.local 1234

# Power/voltage status
vcgencmd_power_report.sh

# Tailscale
tailscale status
```

---

## Notes

- `rtl_tcp` listens on `192.168.11.196:1234`. Consumers (e.g. `rtl_433` on another host)
  connect to this address.
- CUPS web UI is at `http://printserver.local:631` — requires `lpadmin` group membership
  to administer.
- `under_voltage_check.sh` runs hourly via cron, publishing throttle status to MQTT topic
  `/raspberrypi/status` on `home.assistant.lan`. Logs to `~/Logs/`.
- `powerled_status.py` monitors GPIO pin 35 for voltage dips below 4.63V. Run manually
  or add to cron as needed.
- The large `linux-e3376fb94fda798d2a322e9c70789286132a1a9f.tar.gz` (~212MB) in the old
  home directory is kernel source — **do not restore**, not needed.
- `pyenv` and `pipx` are set up via `.bashrc.local` — these will be restored when homeskel
  is cloned, but pyenv itself may need reinstalling:
  ```sh
  curl https://pyenv.run | bash
  ```
