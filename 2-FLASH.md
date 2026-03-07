# 2. Flash ROM + Kernel

## Prerequisites

- Unlocked bootloader
- [ADB and fastboot](https://developer.android.com/tools/releases/platform-tools) on PC
- USB drivers for ADB and fastboot

Download [VoltageOS](https://voltage-os.com/) for raphael.

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

Install the manager APK before rebooting — **Apply update** → **Apply from ADB**:

```bash
adb sideload KernelSU_Next_v1.1.1_12851-release.apk
```

Download from [KernelSU-Next releases](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.1.1).

## Flash Custom Kernel

Stock kernel is missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start without it. The custom kernel also includes [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) for root.

[Build `boot-docker.img` from source](1-BUILD.md), then flash it:

```bash
adb reboot bootloader
fastboot flash boot boot-docker.img
fastboot reboot
```
