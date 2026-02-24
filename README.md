# homelab

## toggle-rtl.sh (`bin/toggle-rtl.sh`)

Toggles between `rtl_433` and `amridm2mqtt`, which contend for the single
RTL-SDR dongle on `printserver.lan:1234` via `rtl_tcp`.

### State

```
~/.config/toggle-rtl/
  active    -> /service/<currently-running-service>
  inactive  -> /service/<currently-stopped-service>
```

### Schedule and timing bias

Cron fires every 3 minutes. The toggle is asymmetric:

- **rtl_433 active**: always toggles on the next cron fire → 3-minute window
- **amridm2mqtt active**: only toggles when `minute % 5 == 0` → 12-minute window

Steady-state cycle: **3 min rtl_433 / 12 min amridm2mqtt**.

### hop_interval constraint

`rtl_433.conf` lists 433.92 MHz first, then 912.6 MHz. With `hop_interval=90`,
rtl_433 reaches 912.6 MHz at t=90s and scans it for ~90s before the toggle
kills it. **Do not increase hop_interval above 90s** — at 180s, rtl_433 spends
its entire 3-minute window on 433.92 MHz and never meaningfully reaches 912.6 MHz.

Retuning the SDR stresses the `brcmfmac` WiFi driver on the Pi. Lower values
than 90s have not been tested.

### Manual invocation

Set `MINUTE=0` to bypass the modulo check:

```sh
MINUTE=0 ~/bin/toggle-rtl.sh
```

## TODOs

- Move MQTT credentials out of `rtl_433.conf` — requires bash shebang in `run`
  for process substitution (`/bin/sh` on FreeBSD is ash-based)
- Move MongoDB credentials out of `docker/unifi.yaml` and `docker/init-mongo.js`
  into a gitignored `.env` file
