#!/data/data/com.termux/files/usr/bin/bash
# Start Docker on Mi 9T Pro
# Usage: su -c bash ~/start-docker.sh

DEBIAN=/data/local/dockerroot
IMG=/data/local/docker.img

echo "[1/5] Setting SELinux permissive..."
setenforce 0

echo "[2/5] Mounting ext4 image..."
if ! mount | grep -q dockerroot; then
    LOOPDEV=$(losetup -f)
    losetup $LOOPDEV $IMG
    mount -t ext4 $LOOPDEV $DEBIAN
fi

echo "[3/5] Mounting filesystems..."
mount --bind /proc $DEBIAN/proc 2>/dev/null
mount --bind /dev $DEBIAN/dev 2>/dev/null
mkdir -p $DEBIAN/dev/pts
mount --bind /dev/pts $DEBIAN/dev/pts 2>/dev/null
mount --bind /sys $DEBIAN/sys 2>/dev/null

# Cgroups
mkdir -p $DEBIAN/sys/fs/cgroup
mount -t tmpfs tmpfs $DEBIAN/sys/fs/cgroup 2>/dev/null
for cg in devices cpu blkio freezer pids; do
    mkdir -p $DEBIAN/sys/fs/cgroup/$cg
    mount -t cgroup -o $cg cgroup $DEBIAN/sys/fs/cgroup/$cg 2>/dev/null
done
mkdir -p $DEBIAN/sys/fs/cgroup/memory
mount -t cgroup -o memory cgroup $DEBIAN/sys/fs/cgroup/memory 2>/dev/null
mkdir -p $DEBIAN/sys/fs/cgroup/cpuset
mount -t cgroup -o cpuset $DEBIAN/sys/fs/cgroup/cpuset 2>/dev/null

echo "nameserver 8.8.8.8" > $DEBIAN/etc/resolv.conf
chmod 1777 $DEBIAN/tmp

echo "[4/5] Starting Docker daemon..."
chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "dockerd --iptables=false --storage-driver=vfs &>/tmp/dockerd.log &"

sleep 8

echo "[5/5] Verifying..."
chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    docker info 2>&1 | head -5

echo ""
echo "Docker is ready!"
echo ""
echo "Enter Debian:"
echo "  su -c \"chroot /data/local/dockerroot /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash\""
echo ""
echo "Run containers:"
echo "  docker run hello-world"
