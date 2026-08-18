# Learned Quirks & Gotchas (Memory Log)

## 1. Android Emulator (QEMU on Windows) Memory Allocation
- **Symptom**: `pc_memory_init: above 4g size: 140000000` / emulator exit code 1 immediately after startup.
- **Cause**: Allocating $\ge 8\text{GB}$ RAM (`hw.ramSize=8192`) causes QEMU 64-bit address reservation conflicts on Windows host hypervisors.
- **Fix**: Set `hw.ramSize=2048` or `3072` in `~/.android/avd/Pixel_7_Pro.avd/config.ini`.

## 2. Touch Hit Targets & Compact States
- When scaling down navigation or list items in compact scroll states, always enforce `ConstrainedBox(constraints: BoxConstraints(minWidth: 44, minHeight: 44))` to preserve mobile accessibility standards.

## 3. Scroll Hysteresis Thresholds
- To avoid jitter during slow reading or micro-scrolling, require $\Delta y > 20\text{pt}$ for downward compaction, but allow immediate expansion on upward flick $\Delta y < -6\text{pt}$ or top bounce `offset <= 0`.
