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

## runrestic (`bin/runrestic`)

Backs up `/media` and the samba jail path
(`/var/virt/iocage/jails/samba.vnet/root/media/capsule`) to Backblaze B2 via
restic. Credentials are read from `~/.restic-env`.

Runs are tagged with hostname, timestamp, and dataset (`media` or
`time-machine`). Output is tee'd to `~/logs/runrestic-YYYYMMDD.log`.

| Env var | Default | Effect |
|---------|---------|--------|
| `DRY_RUN` | `0` | Set to `1` to pass `--dry-run` to restic; log file gets `-dryrun-` suffix |
| `VERBOSE` | `0` | Set to `1` to pass `--verbose` to restic |

## restic-maintenance (`bin/restic-maintenance`)

Enforces retention policy and prunes old snapshots from B2. Runs `restic
forget` with `--prune` (skipped in dry-run), then `restic check` to verify
repository integrity. Output goes to `~/logs/restic-maintenance-YYYYMMDD.log`.

Retention policy:

| Dataset | Daily | Weekly | Monthly | Yearly |
|---------|-------|--------|---------|--------|
| `media` | 7 | 4 | 12 | 5 |
| `time-machine` | 7 | 4 | 6 | 2 |

| Env var | Default | Effect |
|---------|---------|--------|
| `DRY_RUN` | `0` | Set to `1` to pass `--dry-run` to restic; skips prune and post-maintenance snapshot list |
| `VERBOSE` | `0` | Set to `1` to pass `--verbose` to restic |

## UniFi setup

Credentials are not committed. Before the first `docker compose up`:

1. Create `docker/.env` with `MONGO_PASS=<password>`
2. Generate `docker/init-mongo.js` from the template:
   ```sh
   cd docker && envsubst < init-mongo.js.template > init-mongo.js
   ```

## rtl_433 setup

MQTT credentials live in `supervise/rtl_433/env/` (gitignored via `**/*_PASSWORD`):

```sh
echo amridm > supervise/rtl_433/env/MQTT_USERNAME
echo <password> > supervise/rtl_433/env/MQTT_PASSWORD
```
