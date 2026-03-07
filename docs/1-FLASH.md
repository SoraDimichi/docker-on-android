# 1. Flash ROM + Kernel

## Prerequisites

- Unlocked bootloader
- ADB and fastboot on PC

## Flash VoltageOS

1. Boot into recovery: Volume Up + Power
2. Wipe: Format Data ("yes") + Advanced Wipe (Dalvik, Cache, System, Vendor)
3. ADB sideload VoltageOS:
   `adb sideload VoltageOS-5.6-XXXXXXXX-raphael-vanilla.zip`
4. Reboot to bootloader: `adb reboot bootloader`

## Flash Custom Kernel

Stock kernel is missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start without it. Our custom kernel also includes [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) for root.

Download `boot-docker.img` from [Releases](https://github.com/SoraDimichi/docker-on-android/releases), or [build from source](4-KERNEL.md):

```bash
fastboot flash boot boot-docker.img
fastboot reboot
```

## Install KernelSU-Next Manager

After booting, install the manager APK to control root permissions:

```bash
adb install KernelSU_Next_v1.0.8_12701-release.apk
```

Download from [KernelSU-Next releases](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.0.8).
