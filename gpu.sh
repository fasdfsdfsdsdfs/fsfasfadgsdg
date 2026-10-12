#!/usr/bin/env bash
set -Eeuo pipefail

# Run a one-shot GPU health check and save its output to a timestamped log.
# Use --watch for a live refresh every two seconds.

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi was not found in PATH." >&2
  echo "Install or enable the NVIDIA driver, then try again." >&2
  exit 127
fi

if [[ "${1:-}" == "--watch" ]]; then
  if ! command -v watch >/dev/null 2>&1; then
    echo "ERROR: 'watch' is not installed. Run nvidia-smi directly instead." >&2
    exit 127
  fi
  exec watch -n 2 nvidia-smi
fi

if ! nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi could not communicate with the NVIDIA driver/GPU." >&2
  nvidia-smi >&2 || true
  exit 1
fi

log_file="nvidia-smi-$(date +'%Y%m%d-%H%M%S').log"

{
  echo "=== GPU inventory ==="
  nvidia-smi -L
  echo
  echo "=== Full status ==="
  nvidia-smi
  echo
  echo "=== Key metrics (CSV) ==="
  nvidia-smi --query-gpu=timestamp,index,name,driver_version,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv
} | tee "$log_file"

printf '\nSaved report to: %s\n' "$log_file"
