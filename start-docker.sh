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
# cpuset intentionally skipped: Android mounts it with noprefix (files named
# "cpus" instead of "cpuset.cpus"), and the kernel caches this for all later
# mounts. Docker expects prefixed names and fails. Docker works fine without it.

echo "nameserver 8.8.8.8" > $DEBIAN/etc/resolv.conf
chmod 1777 $DEBIAN/tmp

run_chroot() {
    chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"
}

run_chroot bash -c "GODEBUG=netdns=cgo dockerd --iptables=false --storage-driver=vfs &>/tmp/dockerd.log &"

echo -n "Waiting for dockerd"
for i in $(seq 1 30); do
    if run_chroot docker info &>/dev/null; then
        echo " ready (${i}s)"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo "Enter chroot:"
echo "  su -c \"chroot /data/local/dockerroot /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash\""
echo ""
echo "Run nginx:"
echo "  docker run -d --network=host nginx:alpine"
