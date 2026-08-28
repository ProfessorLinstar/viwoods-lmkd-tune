#!/system/bin/sh
# Runs at late_start. Waits for boot, applies sysctl + swap topology,
# forces lmkd to re-read props.

LOG=/data/local/tmp/lmkd_tune.log
SPILL_SIZE=2G

# Add a second zram device below zram0 in priority so the kernel fills
# zram0 first and spills into zram1. Deliberately NOT a resize of zram0:
# changing its disksize requires swapoff, which faults the device's entire
# uncompressed contents back into RAM -- impossible once it is full.
add_spill() {
  [ -e /sys/class/zram-control/hot_add ] || { echo "no zram-control"; return 1; }

  if [ "$(grep -c '^/dev/block/zram' /proc/swaps)" -gt 1 ]; then
    echo "spill device already present"; return 0
  fi

  P0=$(awk '$1 ~ /zram0/ {print $5}' /proc/swaps)
  [ -n "$P0" ] || { echo "zram0 not swapped on"; return 1; }

  D=$(cat /sys/class/zram-control/hot_add) || return 1
  i=0
  until [ -e /dev/block/zram$D ] || [ "$i" -ge 25 ]; do sleep 0.2; i=$((i+1)); done
  [ -e /dev/block/zram$D ] || { echo "zram$D node never appeared"; return 1; }

  # inherit zram0's active algorithm; reset defaults differ per kernel
  ALGO=$(sed -n 's/.*\[\([^]]*\)\].*/\1/p' /sys/block/zram0/comp_algorithm)
  [ -n "$ALGO" ] && echo "$ALGO" > /sys/block/zram$D/comp_algorithm

  # memparse suffix, not shell arithmetic: /system/bin/sh is mksh and
  # $((4*1024*1024*1024)) wraps to 0 on its 32-bit evaluator.
  echo "$SPILL_SIZE" > /sys/block/zram$D/disksize || {
    echo "disksize failed"; echo "$D" > /sys/class/zram-control/hot_remove; return 1; }
  mkswap /dev/block/zram$D >/dev/null 2>&1 || {
    echo "mkswap failed"; echo "$D" > /sys/class/zram-control/hot_remove; return 1; }

  # -p accepts 0..32767 only. A negative P0 is kernel-assigned, so omit
  # -p and let the kernel take the next slot down.
  if [ "$P0" -ge 1 ]; then
    swapon -p $((P0 - 1)) /dev/block/zram$D && echo "zram$D up at $((P0 - 1))"
  else
    swapon /dev/block/zram$D && echo "zram$D up at kernel-assigned prio"
  fi
}

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 1; done
sleep 5

{
  date
  echo 500 > /proc/sys/vm/watermark_scale_factor
  echo "--- spill ---"
  add_spill
  setprop lmkd.reinit 1
  echo "--- state ---"
  echo "watermark_scale_factor=$(cat /proc/sys/vm/watermark_scale_factor)"
  echo "psi_complete_stall_ms=$(getprop ro.lmk.psi_complete_stall_ms)"
  echo "lmkd pid=$(pidof lmkd)"
  cat /proc/swaps
} >> "$LOG" 2>&1
