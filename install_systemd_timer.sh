#!/usr/bin/env bash
set -euo pipefail

EXPECTED_USER="aaronbrox"
CURRENT_USER="$(id -un)"

if [[ "$CURRENT_USER" != "$EXPECTED_USER" ]]; then
  echo "Warning: this timer is intended for user '$EXPECTED_USER' but current user is '$CURRENT_USER'." >&2
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CHECK_SCRIPT="$SCRIPT_DIR/check_disk_space.sh"
UNIT_DIR="$HOME/.config/systemd/user"
SERVICE_UNIT="$UNIT_DIR/disk-space-check.service"
TIMER_UNIT="$UNIT_DIR/disk-space-check.timer"

if [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "Expected executable script at $CHECK_SCRIPT" >&2
  exit 1
fi

mkdir -p "$UNIT_DIR"

cat > "$SERVICE_UNIT" <<UNIT
[Unit]
Description=Check disk usage for / and /data

[Service]
Type=oneshot
ExecStart=${CHECK_SCRIPT}
UNIT

cat > "$TIMER_UNIT" <<'UNIT'
[Unit]
Description=Run disk space check hourly

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl --user daemon-reload
systemctl --user enable --now disk-space-check.timer

echo "Installed and started user timer: disk-space-check.timer"
echo "View status: systemctl --user status disk-space-check.timer"
echo "View alerts: journalctl --user -t disk-space-check"
