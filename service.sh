#!/system/bin/sh
# Runs at late_start. Waits for boot, applies sysctl, forces lmkd to re-read props.
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 1; done
sleep 5

echo 500 > /proc/sys/vm/watermark_scale_factor
setprop lmkd.reinit 1

{
  date
  echo "watermark_scale_factor=$(cat /proc/sys/vm/watermark_scale_factor)"
  echo "psi_complete_stall_ms=$(getprop ro.lmk.psi_complete_stall_ms)"
  echo "lmkd pid=$(pidof lmkd)"
} > /data/local/tmp/lmkd_tune.log 2>&1
