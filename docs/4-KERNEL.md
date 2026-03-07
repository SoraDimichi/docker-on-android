# 4. Building Kernel with Docker Support (VoltageOS)

VoltageOS stock kernel is missing `CONFIG_CGROUP_DEVICE` and `CONFIG_CGROUP_PIDS` — Docker refuses to start without them.

This guide builds the [VoltageOS kernel](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael) with Docker cgroup support enabled, inspired by the [Antigravity kernel](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) which ships these flags out of the box.

> **Automated build:** `cd kernel-build && bash build.sh` handles the entire process below (downloads toolchain, clones kernel, integrates KernelSU-Next, builds, and packs `boot-docker.img`).

## Toolchain

The VoltageOS kernel requires [Android Clang r547379](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/main/clang-r547379) (LLVM 20 with `+mlgo`). System clang will **not** work — the kernel uses ML-guided optimizations (`-mllvm -regalloc-enable-advisor=release`) that only ship with Android's custom Clang build.

```bash
# Download Android Clang (~1 GB)
cd kernel-build
mkdir -p toolchain && cd toolchain
wget "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz" -O clang.tar.gz
mkdir -p clang && tar -xzf clang.tar.gz -C clang && rm clang.tar.gz
cd ..
```

## Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
  bc bison flex libssl-dev libelf-dev make
```

## Build

```bash
# Clone kernel source (inside kernel-build/)
git clone --depth 1 -b 16 \
  https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael.git kernel
cd kernel

# Generate base config
export PATH=$(pwd)/../toolchain/clang/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH
make O=out ARCH=arm64 raphael_defconfig

# Merge Docker config fragment (docker.config is in kernel-build/)
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

The `kernel-build/docker.config` file enables all kernel flags Docker needs. It's merged on top of `raphael_defconfig` via `merge_config.sh`:

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
# Clone mkbootimg (inside kernel-build/)
git clone --depth 1 https://android.googlesource.com/platform/system/tools/mkbootimg

# The VoltageOS ramdisk is included in kernel-build/boot_unpacked/

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

## Flash

**Keep the original VoltageOS `boot.img` as backup** — if it bootloops, recover with `fastboot flash boot boot.img`.

```bash
adb reboot bootloader
fastboot flash boot boot-docker.img
fastboot reboot
```

## Verify

```bash
adb shell su -c "cat /proc/cgroups" | grep -E "device|pids"
```

Should show:

```
devices    X    X    1
pids       X    X    1
```

## What didn't work

| Approach | Problem |
|----------|---------|
| System clang (18/19) | Missing `+mlgo` — `regalloc-enable-advisor=release` fails |
| SOVIET-ANDROID kernel | Different kernel base (BeastRoms) — bootloops on VoltageOS |
| Antigravity pre-built boot.img | Built for EvolutionX ramdisk — bootloops on VoltageOS |
| KernelSU (latest) | Dropped non-GKI support (kernel 4.14 is non-GKI) |
| KernelSU-Next v3.1.0 | Uses `TWA_RESUME` API not available in kernel 4.14 |
| `make Image.gz-dtb` | dtbo build fails (DTC version mismatch) — build `Image.gz` separately |
