# Linux Disk Space Checker (Fedora systemd timer)

This repository contains a user-level disk checker for Fedora that monitors:

- `/` (system disk)
- `/data` (secondary disk)

## Alert policy

A plaintext alert is generated if either condition is true for a mount point:

- Used space is **>= 90%**, or
- Free space is below a GB floor:
  - `/` < **15 GB**
  - `/data` < **50 GB**

Each alert message includes:

- which drive/device (for example `/dev/sda3`)
- mount point (`/` or `/data`)
- usage metric as **used/total** (for example `120G/256G`)

## Requirements from your request

- Frequency: **hourly** (via `OnCalendar=hourly`)
- Notification: **desktop notification** via `notify-send`
- User: intended for user **`aaronbrox`** (user-level timer)
- Logging: **syslog/journal** via `logger`
- Output: **only on problems**
- Remediation: **none** (report only)
- Format: **plaintext**

## Files

- `check_disk_space.sh`: main checker.
- `install_systemd_timer.sh`: installs user-level systemd service/timer units.

## Manual run

```bash
./check_disk_space.sh
```

Exit code:

- `0` = healthy
- `1` = at least one alert condition detected

## Debug mode (force alerts)

To force alert output even when space is healthy, set:

```bash
FORCE_ALERT=1 ./check_disk_space.sh
```

This is useful for validating notifications and journal output.

## Install the user timer (hourly)

Run as your user (`aaronbrox`):

```bash
./install_systemd_timer.sh
```

This creates:

- `~/.config/systemd/user/disk-space-check.service`
- `~/.config/systemd/user/disk-space-check.timer`

Then it runs:

```bash
systemctl --user daemon-reload
systemctl --user enable --now disk-space-check.timer
```

## View status and alerts

```bash
systemctl --user status disk-space-check.timer
journalctl --user -t disk-space-check
```

## Optional threshold overrides

You can override defaults at run time:

- `USED_THRESHOLD_PERCENT` (default `90`)
- `ROOT_MIN_FREE_GB` (default `15`)
- `DATA_MIN_FREE_GB` (default `50`)
- `FORCE_ALERT` (`1` to always alert for testing)

Example:

```bash
USED_THRESHOLD_PERCENT=92 ROOT_MIN_FREE_GB=20 DATA_MIN_FREE_GB=60 ./check_disk_space.sh
```
