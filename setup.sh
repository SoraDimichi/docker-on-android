#!/data/data/com.termux/files/usr/bin/bash
# One-time setup: create ext4 image, install Debian + Docker
# Usage: su -c bash ~/setup.sh

set -e

DEBIAN=/data/local/dockerroot
IMG=/data/local/docker.img
ROOTFS_URL="https://easycli.sh/proot-distro/debian-trixie-aarch64-pd-v4.37.0.tar.xz"

if [ -f "$IMG" ]; then
    echo "Error: $IMG already exists. Remove it first."
    exit 1
fi

echo "[1/5] Creating 8GB ext4 image..."
dd if=/dev/zero of=$IMG bs=1M count=8192
export PATH=/data/data/com.termux/files/usr/bin:$PATH
mkfs.ext4 $IMG
mkdir -p $DEBIAN
LOOPDEV=$(losetup -f)
losetup $LOOPDEV $IMG
mount -t ext4 $LOOPDEV $DEBIAN

echo "[2/5] Downloading Debian rootfs..."
curl -o /data/local/debian.tar.xz $ROOTFS_URL

echo "[3/5] Extracting Debian..."
mkdir -p /data/local/debian
tar xf /data/local/debian.tar.xz -C /data/local/debian
mv /data/local/debian/debian-trixie-aarch64/* /data/local/debian/ 2>/dev/null || true
cp -a /data/local/debian/* $DEBIAN/

echo "[4/5] Cleaning up temp files..."
rm -rf /data/local/debian /data/local/debian.tar.xz

echo "[5/5] Installing Docker..."
setenforce 0
mount --bind /proc $DEBIAN/proc
mount --bind /dev $DEBIAN/dev
mkdir -p $DEBIAN/dev/pts
mount --bind /dev/pts $DEBIAN/dev/pts
mount --bind /sys $DEBIAN/sys
echo "nameserver 8.8.8.8" > $DEBIAN/etc/resolv.conf
chmod 1777 $DEBIAN/tmp

chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "apt update && apt install -y docker.io"

umount $DEBIAN/dev/pts 2>/dev/null
umount $DEBIAN/dev 2>/dev/null
umount $DEBIAN/proc 2>/dev/null
umount $DEBIAN/sys 2>/dev/null
umount $DEBIAN 2>/dev/null
losetup -d $LOOPDEV 2>/dev/null

echo ""
echo "Setup complete. Start Docker with:"
echo "  su -c bash ~/start-docker.sh"
