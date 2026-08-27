#!/system/bin/sh
# post-fs-data: runs before init's `on boot`, so before lmkd (class core) starts.
# Props come from system.prop (also post-fs-data) — lmkd picks them up on its
# own startup read. No lmkd.reinit needed.

LOG=/data/local/tmp/lmkd_tune.log

echo 500 > /proc/sys/vm/watermark_scale_factor 2>/dev/null

{
  echo "=== post-fs-data $(date) ==="
  echo "watermark_scale_factor=$(cat /proc/sys/vm/watermark_scale_factor 2>/dev/null)"
  echo "psi_complete_stall_ms=$(getprop ro.lmk.psi_complete_stall_ms)"
  echo "lmkd_running=$(pidof lmkd 2>/dev/null || echo none)"
} > "$LOG" 2>&1
