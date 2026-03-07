# 1. Build Kernel

VoltageOS stock kernel is missing `CONFIG_CGROUP_DEVICE` and `CONFIG_CGROUP_PIDS` — Docker refuses to start without them.

## Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
  bc bison flex libssl-dev libelf-dev make python3 git curl
```

## Build

```bash
cd kernel-build
bash build.sh
```

Output: `boot-docker.img` in the repo root. Next step: [Flash ROM + Kernel](2-FLASH.md).

The script downloads [Android Clang r547379](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/main/clang-r547379) (~1 GB), clones the [VoltageOS kernel](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael), integrates [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) v1.0.8, applies the Docker config fragment, builds the kernel, and packs the boot image. Takes ~30 min and ~10 GB disk. Read [`build.sh`](kernel-build/build.sh) for details.

## Sources

| Component | Source | License |
|-----------|--------|---------|
| Linux kernel (msm-4.14) | [VoltageOS-Devices/kernel_xiaomi_raphael](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael) @ [`1474f0f`](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael/commit/1474f0f690743d0585a507e3306baa7c7f542ff8) | [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) |
| KernelSU-Next v1.0.8 | [KernelSU-Next/KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) @ [`v1.0.8`](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.0.8) | [GPLv2](https://github.com/KernelSU-Next/KernelSU-Next/blob/next/LICENSE) |
| Android Clang r547379 | [AOSP prebuilts](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/main/clang-r547379) | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |
| mkbootimg | [AOSP system/tools/mkbootimg](https://android.googlesource.com/platform/system/tools/mkbootimg) | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |
| VoltageOS ramdisk | Extracted from [VoltageOS](https://voltage-os.com/) 5.6 boot.img | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |

Inspired by the [Antigravity kernel](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) which ships Docker cgroup flags out of the box.