#!/data/data/com.termux/files/usr/bin/bash
# Stop Docker and unmount chroot
# Usage: su -c bash ~/stop-docker.sh

DEBIAN=/data/local/dockerroot

echo "Stopping Docker..."
chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "kill \$(cat /var/run/docker.pid 2>/dev/null) 2>/dev/null; killall containerd 2>/dev/null"

sleep 3

echo "Unmounting..."
umount $DEBIAN/sys/fs/cgroup/devices 2>/dev/null
umount $DEBIAN/sys/fs/cgroup/cpu 2>/dev/null
umount $DEBIAN/sys/fs/cgroup/blkio 2>/dev/null
umount $DEBIAN/sys/fs/cgroup/freezer 2>/dev/null
umount $DEBIAN/sys/fs/cgroup/pids 2>/dev/null
umount $DEBIAN/sys/fs/cgroup/memory 2>/dev/null
umount $DEBIAN/sys/fs/cgroup/cpuset 2>/dev/null
umount $DEBIAN/sys/fs/cgroup 2>/dev/null
umount $DEBIAN/dev/pts 2>/dev/null
umount $DEBIAN/dev 2>/dev/null
umount $DEBIAN/proc 2>/dev/null
umount $DEBIAN/sys 2>/dev/null

LOOPDEV=$(losetup -a | grep docker.img | cut -d: -f1)
umount $DEBIAN 2>/dev/null
losetup -d $LOOPDEV 2>/dev/null

echo "Done."
