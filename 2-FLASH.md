# 2. Flash ROM + Kernel

## Prerequisites

- Unlocked bootloader
- [ADB and fastboot](https://developer.android.com/tools/releases/platform-tools) on PC
- USB drivers for ADB and fastboot

## Flash Recovery

Flash the VoltageOS recovery (included in the VoltageOS zip):

```bash
fastboot flash recovery recovery.img
```

Reboot into recovery: Volume Up + Power

## Flash VoltageOS

1. Factory reset: **Factory reset** → **Format data / factory reset**
2. Apply update: **Apply update** → **Apply from ADB**
3. Sideload VoltageOS:
   ```bash
   adb sideload VoltageOS-5.6-XXXXXXXX-raphael-vanilla.zip
   ```

## Install KernelSU-Next Manager

Install the manager APK before rebooting — same way as the ROM:

1. **Apply update** → **Apply from ADB**
2. Sideload the APK:
   ```bash
   adb sideload KernelSU_Next_v1.0.8_12701-release.apk
   ```

Download from [KernelSU-Next releases](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.0.8).

You can also install it later via USB debugging: `adb install KernelSU_Next_v1.0.8_12701-release.apk`

## Flash Custom Kernel

Stock kernel is missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start without it. The custom kernel also includes [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) for root.

[Build `boot-docker.img` from source](1-BUILD.md), then flash it:

```bash
adb reboot bootloader
fastboot flash boot boot-docker.img
fastboot reboot
```
