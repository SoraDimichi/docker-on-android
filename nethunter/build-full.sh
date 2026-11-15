#!/usr/bin/env bash
# Build the Kali NetHunter Full installer zip for the Xiaomi Mi 9T Pro (raphael).
# The zip has the kernel and the signed modules of this repo's kernel build (boot-docker.img)
# and the full Kali rootfs. Read docs/03-nethunter.md first.
#
# Usage:  nethunter/build-full.sh
# Output: $WORK_DIR/out/nethunter-<release>-raphael-vos-seventeen-kalifs_full.zip
# Folders: WORK_DIR=<path> (default: nethunter-build/ in this repo, ignored by git)
# and DOA_DIR=<path> (default: this repo, which has kernel-build/ and boot-docker.img).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# --- Pinned versions (change these to update) ---
INSTALLER_REPO="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-installer.git"
# main on 2026-10-31: tag 2026.3 + 5 commits (module install fixes: no rootfs copy left in the module folder)
INSTALLER_COMMIT="aa1dca61435cc8a7e9f4053234c731855329e69b"
RELEASE="2026.3-5-gaa1dca6"   # git describe --tags of INSTALLER_COMMIT, used in the zip name
KERNELS_REPO="https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernels.git"
KERNELS_COMMIT="303ad0f036f942baf29d19e649fe6579da9699fb"   # only devices.yml is checked out
KERNEL_ID="raphael-vos"
# Android 17. build.py has flags up to --sixteen only. Without a flag it takes the
# Android version from the only kernels/<version>/<KERNEL_ID> folder.
ANDROID="seventeen"
ROOTFS="full"

REPO_DIR="$(dirname "$HERE")"
WORK_DIR="${WORK_DIR:-$REPO_DIR/nethunter-build}"
DOA_DIR="${DOA_DIR:-$REPO_DIR}"
KERNEL_OUT="$DOA_DIR/kernel-build/kernel/out"
KERNEL_IMAGE="$KERNEL_OUT/arch/arm64/boot/Image.gz-dtb"
SIGNING_CERT="$KERNEL_OUT/certs/signing_key.x509"
BOOT_IMG="$DOA_DIR/boot-docker.img"
MODULES_ROOT="$DOA_DIR/modules"
INSTALLER="$WORK_DIR/installer"
KERNELS="$INSTALLER/kernels"
DEVICE_DIR="$KERNELS/$ANDROID/$KERNEL_ID"
OUT_DIR="$WORK_DIR/out"

# --- Prerequisites ---

echo "=== Checking prerequisites ==="
for cmd in git python3 openssl unzip cmp sha256sum; do
    command -v "$cmd" >/dev/null || { echo "ERROR: $cmd is required"; exit 1; }
done
if ! python3 -I -c 'import requests, yaml' 2>/dev/null; then
    echo "ERROR: build.py needs requests and yaml: sudo apt-get install python3-requests python3-yaml"
    exit 1
fi
mkdir -p "$WORK_DIR"
# /tmp is RAM (tmpfs) on this PC. The build writes about 6 GB.
if [ "$(stat -f -c %T "$WORK_DIR")" = tmpfs ]; then
    echo "ERROR: $WORK_DIR is on tmpfs (RAM). Set WORK_DIR to a folder on a disk."
    exit 1
fi
FREE_GB=$(df --output=avail -BG "$WORK_DIR" | tail -n 1 | tr -dc '0-9')
if [ "$FREE_GB" -lt 8 ]; then
    echo "ERROR: $WORK_DIR has $FREE_GB GB free. The build needs 8 GB."
    exit 1
fi

# --- Kernel and modules from kernel-build/ ---

KVER_DIRS=("$MODULES_ROOT"/*/)
if [ "${#KVER_DIRS[@]}" -ne 1 ] || [ ! -f "${KVER_DIRS[0]}modules.dep" ]; then
    echo "ERROR: expected exactly one $MODULES_ROOT/<kernel release>/ folder with modules.dep."
    echo "  Build the kernel first: cd $DOA_DIR/kernel-build && bash build.sh"
    exit 1
fi
KVER=$(basename "${KVER_DIRS[0]}")

echo "=== Checking kernel $KVER against boot-docker.img ==="
python3 -I "$HERE/check-kernel.py" "$BOOT_IMG" "$KERNEL_IMAGE" "$SIGNING_CERT" "$MODULES_ROOT/$KVER"

# --- kali-nethunter-installer ---

if [ ! -d "$INSTALLER/.git" ]; then
    echo "=== Fetching kali-nethunter-installer $INSTALLER_COMMIT ==="
    git init -q "$INSTALLER"
    git -C "$INSTALLER" remote add origin "$INSTALLER_REPO"
    git -C "$INSTALLER" fetch -q --depth 1 origin "$INSTALLER_COMMIT"
    git -C "$INSTALLER" checkout -q FETCH_HEAD
fi
if [ "$(git -C "$INSTALLER" rev-parse HEAD)" != "$INSTALLER_COMMIT" ]; then
    echo "ERROR: $INSTALLER is not at $INSTALLER_COMMIT. Move or remove it, then run this script again."
    exit 1
fi

# --- kali-nethunter-kernels: devices.yml only (sparse checkout) ---

if [ ! -d "$KERNELS/.git" ]; then
    echo "=== Fetching devices.yml of kali-nethunter-kernels $KERNELS_COMMIT ==="
    git init -q "$KERNELS"
    git -C "$KERNELS" remote add origin "$KERNELS_REPO"
    git -C "$KERNELS" sparse-checkout set --no-cone /devices.yml /README.md
    git -C "$KERNELS" fetch -q --depth 1 --filter=blob:none origin "$KERNELS_COMMIT"
    git -C "$KERNELS" checkout -q FETCH_HEAD
fi
if [ "$(git -C "$KERNELS" rev-parse HEAD)" != "$KERNELS_COMMIT" ]; then
    echo "ERROR: $KERNELS is not at $KERNELS_COMMIT. Move or remove it, then run this script again."
    exit 1
fi

echo "=== Adding $KERNEL_ID to devices.yml ==="
# Start from the pinned file each time, so the entry is in it only once
git -C "$KERNELS" checkout -q -- devices.yml
cat "$HERE/$KERNEL_ID.yml" >> "$KERNELS/devices.yml"

echo "=== Copying kernel and modules to kernels/$ANDROID/$KERNEL_ID ==="
# modules/system_root/lib/modules/<release>: the Magisk module install copies
# modules/*/lib to /system/lib in the module (update-magisk: push_modules)
rm -rf "${KERNELS:?}/$ANDROID"
mkdir -p "$DEVICE_DIR/modules/system_root/lib/modules"
cp "$KERNEL_IMAGE" "$DEVICE_DIR/Image.gz-dtb"
cp -r "$MODULES_ROOT/$KVER" "$DEVICE_DIR/modules/system_root/lib/modules/"

# --- Build ---

echo "=== Building the zip with build.py ==="
cd "$INSTALLER"
rm -f nethunter-*.zip
python3 -I build.py --kernel "$KERNEL_ID" --rootfs "$ROOTFS" --release "$RELEASE"
ZIP_NAME="nethunter-$RELEASE-$KERNEL_ID-$ANDROID-kalifs_$ROOTFS.zip"
mkdir -p "$OUT_DIR"
mv -f "$ZIP_NAME" "$OUT_DIR/"
ZIP="$OUT_DIR/$ZIP_NAME"

# --- Check the zip ---

echo "=== Checking the zip ==="
unzip -tq "$ZIP"
unzip -l "$ZIP" customize.sh module.prop kernel-nethunter.zip "kalifs-$ROOTFS-arm64.tar.xz" \
    "boot-patcher/modules/system_root/lib/modules/$KVER/modules.dep" >/dev/null
unzip -p "$ZIP" boot-patcher/Image.gz-dtb | cmp - "$KERNEL_IMAGE"
KERNEL_ZIP=$(mktemp -p "$WORK_DIR" kernel-nethunter.XXXXXX.zip)
unzip -p "$ZIP" kernel-nethunter.zip > "$KERNEL_ZIP"
unzip -p "$KERNEL_ZIP" Image.gz-dtb | cmp - "$KERNEL_IMAGE"
rm -f "$KERNEL_ZIP"
echo "OK: the zip has the kernel of boot-docker.img and the modules for $KVER"

(cd "$OUT_DIR" && sha256sum "$ZIP_NAME" > "$ZIP_NAME.sha256")
echo ""
echo "=== Done ==="
echo "Zip:     $ZIP"
echo "Size:    $(stat -c %s "$ZIP") bytes"
echo "SHA-256: $(cut -d' ' -f1 "$ZIP.sha256")"
echo "Rootfs:  $(sha256sum "$INSTALLER/data/rootfs/kalifs-$ROOTFS-arm64.tar.xz" | cut -d' ' -f1)  kalifs-$ROOTFS-arm64.tar.xz"
echo "Install: docs/03-nethunter.md"
