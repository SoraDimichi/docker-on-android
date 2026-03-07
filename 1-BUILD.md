# 1. Building Kernel with Docker Support (VoltageOS)

VoltageOS stock kernel is missing `CONFIG_CGROUP_DEVICE` and `CONFIG_CGROUP_PIDS` — Docker refuses to start without them.

This guide builds the [VoltageOS kernel](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael) with Docker cgroup support enabled, inspired by the [Antigravity kernel](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) which ships these flags out of the box.

> **Automated build:** `bash build.sh` handles the entire process below (downloads toolchain, clones kernel, integrates KernelSU-Next, builds, and packs `boot-docker.img`).

## Sources

The build script downloads and uses the following components:

| Component | Source | License |
|-----------|--------|---------|
| Linux kernel (msm-4.14, branch 16) | [VoltageOS-Devices/kernel_xiaomi_raphael](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael) @ [`1474f0f`](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael/commit/1474f0f690743d0585a507e3306baa7c7f542ff8) | [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) |
| KernelSU-Next v1.0.8 | [KernelSU-Next/KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) @ [`v1.0.8`](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.0.8) | [GPLv2](https://github.com/KernelSU-Next/KernelSU-Next/blob/next/LICENSE) |
| Android Clang r547379 (toolchain) | [AOSP prebuilts](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/main/clang-r547379) | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |
| mkbootimg (boot image packer) | [AOSP system/tools/mkbootimg](https://android.googlesource.com/platform/system/tools/mkbootimg) | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |
| VoltageOS ramdisk (`boot_unpacked/`) | Extracted from [VoltageOS](https://voltage-os.com/) 5.6 boot.img | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |

### Modifications applied at build time

1. **Docker config fragment** (`docker.config`) — enables 26 cgroup/namespace/netfilter flags via `merge_config.sh`
2. **KernelSU-Next v1.0.8** — integrated via upstream `setup.sh`, adds `drivers/kernelsu/` module with kprobes hook
3. **Disable `KSU_UMOUNT`** — `path_umount` does not exist in kernel 4.14; commented out in `drivers/kernelsu/Makefile`
4. **Enable `KPROBES`, `HAVE_KPROBES`, `KSU`** — required for KernelSU-Next kprobes hook mode

## Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
  bc bison flex libssl-dev libelf-dev make python3 git curl
```

## Toolchain

The VoltageOS kernel requires [Android Clang r547379](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/main/clang-r547379) (LLVM 20 with `+mlgo`). System clang will **not** work — the kernel uses ML-guided optimizations (`-mllvm -regalloc-enable-advisor=release`) that only ship with Android's custom Clang build.

```bash
# Download Android Clang (~1 GB)
mkdir -p toolchain && cd toolchain
wget "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz" -O clang.tar.gz
mkdir -p clang && tar -xzf clang.tar.gz -C clang && rm clang.tar.gz
cd ..
```

## Build

```bash
# Clone kernel source
git clone --depth 1 -b 16 \
  https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael.git kernel
cd kernel

# Generate base config
export PATH=$(pwd)/../toolchain/clang/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH
make O=out ARCH=arm64 raphael_defconfig

# Merge Docker config fragment
ARCH=arm64 scripts/kconfig/merge_config.sh -m -O out out/.config ../docker.config

# Resolve dependencies
make O=out ARCH=arm64 olddefconfig

# Verify flags
grep -E "CGROUP_DEVICE|CGROUP_PIDS" out/.config

# Build kernel image (skip dtbo — DTC version mismatch)
make -j$(nproc) O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
  Image.gz

# Concatenate kernel + device tree
cat out/arch/arm64/boot/Image.gz \
  out/arch/arm64/boot/dts/qcom/sm8150-v2.dtb \
  > out/arch/arm64/boot/Image.gz-dtb
```

Output: `out/arch/arm64/boot/Image.gz-dtb`

## Docker config fragment

The `docker.config` file enables all kernel flags Docker needs. It's merged on top of `raphael_defconfig` via `merge_config.sh`:

```
CONFIG_NAMESPACES=y
CONFIG_NET_NS=y
CONFIG_PID_NS=y
CONFIG_IPC_NS=y
CONFIG_UTS_NS=y
CONFIG_USER_NS=y
CONFIG_CGROUPS=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_SCHED=y
CONFIG_CPUSETS=y
CONFIG_MEMCG=y
CONFIG_KEYS=y
CONFIG_VETH=y
CONFIG_OVERLAY_FS=y
CONFIG_BRIDGE=y
CONFIG_NETFILTER=y
CONFIG_NETFILTER_ADVANCED=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
CONFIG_NETFILTER_XT_MATCH_IPVS=y
CONFIG_IP_NF_TARGET_MASQUERADE=y
CONFIG_NETFILTER_XT_MARK=y
CONFIG_IP_NF_NAT=y
CONFIG_NF_NAT=y
CONFIG_POSIX_MQUEUE=y
```

## Create boot.img

The kernel image alone isn't flashable. Pack it with the VoltageOS ramdisk:

```bash
# Clone mkbootimg
git clone --depth 1 https://android.googlesource.com/platform/system/tools/mkbootimg

# The VoltageOS ramdisk is included in boot_unpacked/

# Repack with new kernel
python3 mkbootimg/mkbootimg.py \
  --kernel out/arch/arm64/boot/Image.gz-dtb \
  --ramdisk ../boot_unpacked/ramdisk.cpio.gz \
  --cmdline "console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 buildvariant=user" \
  --base 0x00000000 \
  --kernel_offset 0x00008000 \
  --ramdisk_offset 0x01000000 \
  --tags_offset 0x00000100 \
  --pagesize 4096 \
  --header_version 0 \
  --os_patch_level 2026-02 \
  -o boot-docker.img
```

Output: `boot-docker.img` — flash it following [Flash ROM + Kernel](2-FLASH.md).

## What didn't work

| Approach | Problem |
|----------|---------|
| System clang (18/19) | Missing `+mlgo` — `regalloc-enable-advisor=release` fails |
| SOVIET-ANDROID kernel | Different kernel base (BeastRoms) — bootloops on VoltageOS |
| Antigravity pre-built boot.img | Built for EvolutionX ramdisk — bootloops on VoltageOS |
| KernelSU (latest) | Dropped non-GKI support (kernel 4.14 is non-GKI) |
| KernelSU-Next v3.1.0 | Uses `TWA_RESUME` API not available in kernel 4.14 |
| `make Image.gz-dtb` | dtbo build fails (DTC version mismatch) — build `Image.gz` separately |
