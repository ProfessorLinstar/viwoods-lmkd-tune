# lmkd-tune

Magisk module for Viwoods AiPaper (Helio G96, 4GB RAM, ~2.2GB zram).

## What it changes

| Knob | Stock | This module | AOSP default |
|---|---|---|---|
| `ro.lmk.psi_complete_stall_ms` | 150 | 2000 | 700 |
| `vm.watermark_scale_factor` | 300 | 500 | 10 |

## Why

Capture analysis showed 27 lmkd kills in a 37s window while MemAvailable
never dropped below 892MB. Kills were driven by full-PSI stalls and free-page
watermark breaches, not by actual memory exhaustion. 12 of 15 kills citing
"swap is low" reported swap-free values contradicted by `pswpout` deltas.

`filecache_min_kb` is deliberately NOT set: it makes lmkd kill *more*
(it keeps killing until filecache reaches the target after thrashing is
detected), which is the wrong direction here.

## Build

    make          # -> module.zip
    make install  # -> /sdcard/Download/lmkd_tune.zip

Install via Magisk app -> Modules -> Install from storage, then reboot.

## Verify after reboot

    cat /data/local/tmp/lmkd_tune.log
    getprop ro.lmk.psi_complete_stall_ms
    cat /proc/sys/vm/watermark_scale_factor
