#!/usr/bin/env bash
# Build VoltageOS kernel with Docker cgroup support + NetHunter USB features
# + KernelSU-Next for Xiaomi Mi 9T Pro (raphael)
#
# Usage: cd kernel-build && bash build.sh
# Output: ../boot-docker.img and ../modules/<kernel version>/ (kernel modules)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Pinned versions (change these to update) ---
CLANG_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz"
KERNEL_REPO="https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael.git"
KERNEL_BRANCH="17"
KERNEL_COMMIT="794b2ef62510f29174be9cd0d682ef5e305e2b81"
MKBOOTIMG_REPO="https://android.googlesource.com/platform/system/tools/mkbootimg"
MKBOOTIMG_COMMIT="d2bb0af5ba6d3198a3e99529c97eda1be0b5a093"
KSU_VERSION="v1.1.1"
# Copy these from the stock boot.img of the ROM (boot_unpacked/boot_params.txt).
# A lower value than the stock boot image makes Android's keystore refuse the boot as a downgrade.
OS_VERSION="17.0.0"
OS_PATCH_LEVEL="2026-10"

TOOLCHAIN_DIR="$SCRIPT_DIR/toolchain"
KERNEL_DIR="$SCRIPT_DIR/kernel"
MKBOOTIMG_DIR="$SCRIPT_DIR/mkbootimg"
BOOT_UNPACKED="$SCRIPT_DIR/boot_unpacked"
DOCKER_CONFIG="$SCRIPT_DIR/docker.config"
NETHUNTER_CONFIG="$SCRIPT_DIR/nethunter.config"
PATCHES_DIR="$SCRIPT_DIR/patches"
OUTPUT="$REPO_ROOT/boot-docker.img"
MODULES_OUTPUT="$REPO_ROOT/modules"

# --- Prerequisites ---

echo "=== Checking prerequisites ==="
for cmd in python3 git curl make bc bison flex; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd is required but not found"
        exit 1
    fi
done

if ! command -v aarch64-linux-gnu-gcc &>/dev/null; then
    echo "ERROR: aarch64-linux-gnu-gcc not found. Install with:"
    echo "  sudo apt-get install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu libssl-dev libelf-dev"
    exit 1
fi

# --- Toolchain ---

if [ ! -d "$TOOLCHAIN_DIR/clang/bin" ]; then
    echo "=== Downloading Android Clang r547379 (~1 GB) ==="
    mkdir -p "$TOOLCHAIN_DIR"
    curl -L "$CLANG_URL" -o "$TOOLCHAIN_DIR/clang.tar.gz"
    mkdir -p "$TOOLCHAIN_DIR/clang"
    tar -xzf "$TOOLCHAIN_DIR/clang.tar.gz" -C "$TOOLCHAIN_DIR/clang"
    rm "$TOOLCHAIN_DIR/clang.tar.gz"
else
    echo "=== Toolchain already present ==="
fi

export PATH="$TOOLCHAIN_DIR/clang/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH"

# --- Kernel source ---

if [ ! -d "$KERNEL_DIR/.git" ]; then
    echo "=== Cloning VoltageOS kernel (commit $KERNEL_COMMIT) ==="
    git clone --depth 1 -b "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_DIR"
    ACTUAL=$(git -C "$KERNEL_DIR" rev-parse HEAD)
    if [ "$ACTUAL" != "$KERNEL_COMMIT" ]; then
        echo "WARNING: kernel commit changed upstream!"
        echo "  Expected: $KERNEL_COMMIT"
        echo "  Got:      $ACTUAL"
        echo "  The build may produce a different kernel. Press Enter to continue or Ctrl+C to abort."
        read -r
    fi
else
    ACTUAL=$(git -C "$KERNEL_DIR" rev-parse HEAD)
    if [ "$ACTUAL" != "$KERNEL_COMMIT" ]; then
        echo "ERROR: $KERNEL_DIR is at $ACTUAL, not at $KERNEL_COMMIT."
        echo "  Move or remove it, then run this script again."
        exit 1
    fi
    echo "=== Kernel source already present ==="
fi

# --- KernelSU-Next ---

if [ ! -d "$KERNEL_DIR/drivers/kernelsu" ]; then
    echo "=== Integrating KernelSU-Next $KSU_VERSION ==="
    cd "$KERNEL_DIR"
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/$KSU_VERSION/kernel/setup.sh" | bash -s "$KSU_VERSION"

    # Disable KSU_UMOUNT — path_umount not available on kernel < 5.9
    sed -i 's/^ccflags-y += -DKSU_UMOUNT/# ccflags-y += -DKSU_UMOUNT  # path_umount not available on kernel < 5.9/' \
        "$KERNEL_DIR/drivers/kernelsu/Makefile"
else
    echo "=== KernelSU-Next already integrated ==="
fi

# --- Local patches ---
# KernelSU-Next needs backports that a 4.14 kernel does not have (path_umount, seccomp filter_count)

cd "$KERNEL_DIR"
for patch in "$PATCHES_DIR"/*.patch; do
    if git apply --reverse --check "$patch" 2>/dev/null; then
        echo "=== Already applied: $(basename "$patch") ==="
    else
        echo "=== Applying $(basename "$patch") ==="
        git apply "$patch"
    fi
done

# --- Configure ---

echo "=== Configuring kernel ==="
cd "$KERNEL_DIR"

make O=out ARCH=arm64 raphael_defconfig

# Merge Docker and NetHunter config fragments
ARCH=arm64 scripts/kconfig/merge_config.sh -m -O out out/.config "$DOCKER_CONFIG" "$NETHUNTER_CONFIG"

# Enable KernelSU kprobes hook
scripts/config --file out/.config --enable KPROBES --enable HAVE_KPROBES --enable KSU

make O=out ARCH=arm64 olddefconfig

# Verify critical flags
echo "=== Verifying config ==="
grep -E "CONFIG_CGROUP_DEVICE|CONFIG_CGROUP_PIDS|CONFIG_KSU" out/.config
# olddefconfig silently drops an option when one of its dependencies is off
MISSING=$(grep -h '^CONFIG_' "$DOCKER_CONFIG" "$NETHUNTER_CONFIG" | grep -vxF -f out/.config || true)
if [ -n "$MISSING" ]; then
    echo "WARNING: these fragment options are not in out/.config:"
    echo "$MISSING"
fi

# --- Build ---

echo "=== Building kernel ==="
make -j"$(nproc)" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    Image.gz

# Build DTB separately (dtbo fails due to DTC version mismatch)
make -j"$(nproc)" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    dtbs 2>/dev/null || true

# Concatenate kernel + device tree
cat out/arch/arm64/boot/Image.gz \
    out/arch/arm64/boot/dts/qcom/sm8150-v2.dtb \
    > out/arch/arm64/boot/Image.gz-dtb

echo "=== Kernel built: out/arch/arm64/boot/Image.gz-dtb ==="

# Kernel modules (mac80211_hwsim, ath9k_htc and its helpers). modules_install strips and signs them:
# the kernel has MODULE_SIG_FORCE and loads only modules signed by this build.
echo "=== Building modules ==="
make -j"$(nproc)" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    modules
rm -rf out/modules_install
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    INSTALL_MOD_PATH=modules_install INSTALL_MOD_STRIP=1 modules_install
# Keep the lib/modules/<version> tree with modules.dep, so modprobe on the phone loads the dependencies
rm -rf "$MODULES_OUTPUT"
mkdir -p "$MODULES_OUTPUT"
rm -f out/modules_install/lib/modules/*/build out/modules_install/lib/modules/*/source
cp -r out/modules_install/lib/modules/* "$MODULES_OUTPUT/"

# --- mkbootimg ---

if [ ! -d "$MKBOOTIMG_DIR" ]; then
    echo "=== Cloning mkbootimg (commit $MKBOOTIMG_COMMIT) ==="
    git init "$MKBOOTIMG_DIR"
    git -C "$MKBOOTIMG_DIR" remote add origin "$MKBOOTIMG_REPO"
    git -C "$MKBOOTIMG_DIR" fetch --depth 1 origin "$MKBOOTIMG_COMMIT"
    git -C "$MKBOOTIMG_DIR" checkout FETCH_HEAD
else
    echo "=== mkbootimg already present ==="
fi

# --- Pack boot image ---

echo "=== Packing boot-docker.img ==="
python3 "$MKBOOTIMG_DIR/mkbootimg.py" \
    --kernel out/arch/arm64/boot/Image.gz-dtb \
    --ramdisk "$BOOT_UNPACKED/ramdisk.cpio.lz4" \
    --cmdline "console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 buildvariant=user" \
    --base 0x00000000 \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x01000000 \
    --tags_offset 0x00000100 \
    --pagesize 4096 \
    --header_version 0 \
    --os_version "$OS_VERSION" \
    --os_patch_level "$OS_PATCH_LEVEL" \
    -o "$OUTPUT"

echo ""
echo "=== Done ==="
echo "Output: $OUTPUT"
echo "SHA256: $(sha256sum "$OUTPUT")"
echo "Modules: $(ls "$MODULES_OUTPUT")"
echo ""
echo "Flash with:"
echo "  fastboot flash boot boot-docker.img"
echo "  fastboot reboot"
