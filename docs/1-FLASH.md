# 1. Flash ROM + Kernel

## Prerequisites

- Unlocked bootloader
- ADB and fastboot on PC

## Flash EvolutionX + Magisk

1. Boot into recovery: Volume Up + Power
2. Wipe: Format Data ("yes") + Advanced Wipe (Dalvik, Cache, System, Vendor)
3. ADB sideload EvolutionX (recovery included with the ROM):
   `adb sideload EvolutionX-16.0-XXXXXXXX-raphael-XX.X.X-Official.zip`
4. Rename Magisk APK to .zip, sideload: `adb sideload Magisk-vXX.X.zip`
5. Reboot

## Flash Antigravity Kernel

Stock kernel is missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start without it.

Download from [releases](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity/releases).

```bash
adb reboot bootloader
fastboot flash boot boot-raphael-docker-v1.0.img
fastboot reboot
```
