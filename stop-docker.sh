#!/data/data/com.termux/files/usr/bin/bash
# Usage: su -c bash ~/stop-docker.sh

DEBIAN=/data/local/dockerroot

chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "kill \$(cat /var/run/docker.pid 2>/dev/null) 2>/dev/null; killall containerd 2>/dev/null"

sleep 3

for m in sys/fs/cgroup/{devices,cpu,blkio,freezer,pids,memory,cpuset} sys/fs/cgroup dev/pts dev proc sys; do
    umount $DEBIAN/$m 2>/dev/null
done

LOOPDEV=$(losetup -a | grep docker.img | cut -d: -f1)
umount $DEBIAN 2>/dev/null
losetup -d $LOOPDEV 2>/dev/null

echo "Done."
