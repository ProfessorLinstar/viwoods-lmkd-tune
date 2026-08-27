# lmkd-tune

Magisk module for Viwoods AiPaper (Helio G96, 4GB RAM, ~2.2GB zram).

## What it changes

| Knob | Stock | This module | AOSP default |
|---|---|---|---|
| `ro.lmk.psi_complete_stall_ms` | 150 | 2000 | 700 |
| `vm.watermark_scale_factor` | 300 | 500 | 10 |

## Timing

lmkd is `class core`, started at init's `on boot` trigger. Magisk applies
`system.prop` and runs `post-fs-data.sh` during post-fs-data, which is
earlier — so lmkd reads the prop on its own startup and no `lmkd.reinit`
is required.

`service.sh` does not apply anything. It only checks whether vendor init
clobbered `watermark_scale_factor` after post-fs-data, re-applies if so,
and records the result. Check `clobbered_after_post_fs_data` in the log.

## Why

Capture analysis showed 27 lmkd kills in a 37s window while MemAvailable
never dropped below 892MB. Kills were driven by full-PSI stalls and free-page
watermark breaches, not actual memory exhaustion. 12 of 15 kills citing
"swap is low" reported swap-free values contradicted by `pswpout` deltas.

`filecache_min_kb` is deliberately NOT set: it makes lmkd kill *more* — it
keeps killing background processes until filecache reaches the target once
thrashing is detected — which is the wrong direction here.

## Build

    make          # -> module.zip
    make install  # -> /sdcard/Download/lmkd_tune.zip

Install via Magisk app -> Modules -> Install from storage, then reboot.

## Verify

    cat /data/local/tmp/lmkd_tune.log
