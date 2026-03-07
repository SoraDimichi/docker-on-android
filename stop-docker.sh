#!/data/data/com.termux/files/usr/bin/bash
# Usage: su -c bash ~/stop-docker.sh

DEBIAN=/data/local/dockerroot

echo "Stopping Docker..."
chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "kill \$(cat /var/run/docker.pid 2>/dev/null) 2>/dev/null; killall containerd 2>/dev/null" 2>/dev/null

sleep 3

echo "Unmounting..."
# Lazy unmount everything under dockerroot (handles duplicates and busy mounts)
while mount | grep -q "on $DEBIAN"; do
    mount | grep "on $DEBIAN" | awk '{print $3}' | sort -r | while read m; do
        umount -l "$m" 2>/dev/null
    done
    sleep 1
done

LOOPDEV=$(losetup -a | grep docker.img | cut -d: -f1)
losetup -d $LOOPDEV 2>/dev/null

echo "Done."
