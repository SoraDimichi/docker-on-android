#!/data/data/com.termux/files/usr/bin/bash
# Usage: su -c bash ~/start-docker.sh

DEBIAN=/data/local/dockerroot
IMG=/data/local/docker.img

setenforce 0

if ! mount | grep -q dockerroot; then
    LOOPDEV=$(losetup -f)
    losetup $LOOPDEV $IMG
    mount -t ext4 $LOOPDEV $DEBIAN
fi

mount --bind /proc $DEBIAN/proc 2>/dev/null
mount --bind /dev $DEBIAN/dev 2>/dev/null
mkdir -p $DEBIAN/dev/pts
mount --bind /dev/pts $DEBIAN/dev/pts 2>/dev/null
mount --bind /sys $DEBIAN/sys 2>/dev/null

mkdir -p $DEBIAN/sys/fs/cgroup
mount -t tmpfs tmpfs $DEBIAN/sys/fs/cgroup 2>/dev/null
for cg in devices cpu blkio freezer pids; do
    mkdir -p $DEBIAN/sys/fs/cgroup/$cg
    mount -t cgroup -o $cg cgroup $DEBIAN/sys/fs/cgroup/$cg 2>/dev/null
done
mkdir -p $DEBIAN/sys/fs/cgroup/memory
mount -t cgroup -o memory cgroup $DEBIAN/sys/fs/cgroup/memory 2>/dev/null
mkdir -p $DEBIAN/sys/fs/cgroup/cpuset
mount -t cgroup -o cpuset cgroup $DEBIAN/sys/fs/cgroup/cpuset 2>/dev/null

echo "nameserver 8.8.8.8" > $DEBIAN/etc/resolv.conf
chmod 1777 $DEBIAN/tmp

chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "dockerd --iptables=false --storage-driver=vfs &>/tmp/dockerd.log &"

sleep 8

chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    docker info 2>&1 | head -3

echo ""
echo "Ready. Enter chroot:"
echo "  su -c \"chroot /data/local/dockerroot /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash\""
echo ""
echo "Run nginx:"
echo "  docker run -d --network=host nginx:alpine"
