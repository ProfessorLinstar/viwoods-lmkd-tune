#!/system/bin/sh
# late_start: verification only. Detects whether vendor init clobbered the
# sysctl after post-fs-data, and re-applies if so.

LOG=/data/local/tmp/lmkd_tune.log
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 1; done

WSF=$(cat /proc/sys/vm/watermark_scale_factor 2>/dev/null)
CLOBBERED=no
if [ "$WSF" != "500" ]; then
  CLOBBERED="yes (found $WSF)"
  echo 500 > /proc/sys/vm/watermark_scale_factor 2>/dev/null
fi

{
  echo "=== late_start $(date) ==="
  echo "clobbered_after_post_fs_data=$CLOBBERED"
  echo "watermark_scale_factor=$(cat /proc/sys/vm/watermark_scale_factor 2>/dev/null)"
  echo "psi_complete_stall_ms=$(getprop ro.lmk.psi_complete_stall_ms)"
  echo "lmkd_pid=$(pidof lmkd 2>/dev/null || echo none)"
} >> "$LOG" 2>&1
