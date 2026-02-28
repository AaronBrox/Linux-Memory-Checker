#!/usr/bin/env bash
set -euo pipefail

# Threshold configuration
USED_THRESHOLD_PERCENT=${USED_THRESHOLD_PERCENT:-90}
ROOT_MIN_FREE_GB=${ROOT_MIN_FREE_GB:-15}
DATA_MIN_FREE_GB=${DATA_MIN_FREE_GB:-50}
# Set FORCE_ALERT=1 to emit alert output even when thresholds are not met.
FORCE_ALERT=${FORCE_ALERT:-0}

SCRIPT_TAG="disk-space-check"

log_alert() {
  local message="$1"

  # journal/syslog output
  logger -t "$SCRIPT_TAG" -- "$message"

  # desktop notification (best effort)
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Disk Space Alert" "$message" || true
  fi
}

check_mount() {
  local mount_point="$1"
  local min_free_gb="$2"

  if ! df_output=$(df -BG --output=source,size,used,avail,pcent,target "$mount_point" 2>/dev/null | tail -n 1); then
    echo "Could not read disk usage for ${mount_point}."
    return
  fi

  local source
  local total_gb
  local used_gb
  local avail_gb
  local used_percent
  local target

  source=$(awk '{print $1}' <<< "$df_output")
  total_gb=$(awk '{print $2}' <<< "$df_output" | tr -d 'G')
  used_gb=$(awk '{print $3}' <<< "$df_output" | tr -d 'G')
  avail_gb=$(awk '{print $4}' <<< "$df_output" | tr -d 'G')
  used_percent=$(awk '{print $5}' <<< "$df_output" | tr -d '%')
  target=$(awk '{print $6}' <<< "$df_output")

  if [[ -z "$source" || -z "$total_gb" || -z "$used_gb" || -z "$avail_gb" || -z "$used_percent" || -z "$target" ]]; then
    echo "Unexpected df output for ${mount_point}: ${df_output}"
    return
  fi

  if (( used_percent >= USED_THRESHOLD_PERCENT || avail_gb < min_free_gb )); then
    echo "Drive ${source} mounted at ${target}: ${used_gb}G/${total_gb}G used (${used_percent}% used, ${avail_gb}G free). Thresholds: used >= ${USED_THRESHOLD_PERCENT}% OR free < ${min_free_gb}G."
  elif [[ "$FORCE_ALERT" == "1" ]]; then
    echo "[DEBUG/FORCED ALERT] Drive ${source} mounted at ${target}: ${used_gb}G/${total_gb}G used (${used_percent}% used, ${avail_gb}G free). Thresholds currently not breached."
  fi
}

alerts=()

while IFS= read -r line; do
  [[ -n "$line" ]] && alerts+=("$line")
done < <(check_mount "/" "$ROOT_MIN_FREE_GB")

while IFS= read -r line; do
  [[ -n "$line" ]] && alerts+=("$line")
done < <(check_mount "/data" "$DATA_MIN_FREE_GB")

if (( ${#alerts[@]} > 0 )); then
  full_message=$(printf '%s\n' "${alerts[@]}")
  log_alert "$full_message"
  exit 1
fi

# Healthy state: no output.
exit 0
