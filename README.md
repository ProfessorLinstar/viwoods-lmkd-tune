# lmkd-tune

Magisk module for Viwoods AiPaper (Helio G96, 4GB RAM).

## What it changes

| Knob | Stock | This module | AOSP default |
| --- | --- | --- | --- |
| `ro.lmk.psi_complete_stall_ms` | 150 | 900 | 700 |
| `vm.watermark_scale_factor` | 300 | 500 | 10 |
| swap devices | zram0 only (~2.1GB) | + zram1 spill (2GB) | n/a |

## Why

**Swap capacity.** zram0 runs to 100% full under normal use. At that point the
kernel cannot reclaim anonymous pages at all, and kswapd falls back to
shredding file cache -- measured at SwapFree=0 with MemAvailable at 74MB.
`service.sh` hot-adds a second zram device below zram0 in priority, so the
kernel fills zram0 first and spills into zram1.

This is deliberately *not* a resize of zram0. Changing `disksize` requires
`swapoff`, which faults the device's entire uncompressed contents back into
RAM -- impossible once it is full (measured: 1670MB to fault back into 853MB
available). `hot_add` has no such constraint and works at any time.

**PSI.** Stock 150ms is far too twitchy. 2000ms breaks lmkd on this device;
900 is the working value.

`filecache_min_kb` is NOT set: it makes lmkd kill *more*, since it keeps
killing until filecache reaches the target once thrashing is detected.

`direct_reclaim_threshold_ms` is NOT set: AOSP defaults it to 0 (disabled),
so setting it would enable a kill condition rather than relax one.

## Notes

- zram1 inherits zram0's active compression algorithm (lz4; this kernel has
  no zstd).
- Priority is read from `/proc/swaps` at runtime. zram0 boots at a
  kernel-assigned -2, and `swapon -p` only accepts 0-32767, so a negative
  priority means the spill device is added without `-p` and the kernel takes
  the next slot down.
- Sizes use memparse suffixes (`2G`), not shell arithmetic: `/system/bin/sh`
  is mksh and `$((4*1024*1024*1024))` wraps to 0 on its 32-bit evaluator.
- Uninstall leaves zram1 active until reboot.

## Build

```
make          # -> module.zip
make install  # -> /sdcard/Download/lmkd_tune.zip
```

Install via Magisk app -> Modules -> Install from storage, then reboot.

## Verify after reboot

```
cat /data/local/tmp/lmkd_tune.log
cat /proc/swaps
getprop ro.lmk.psi_complete_stall_ms
cat /proc/sys/vm/watermark_scale_factor
```
