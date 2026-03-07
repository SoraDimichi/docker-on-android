#!/data/data/com.termux/files/usr/bin/bash
# Usage: su -c bash ~/stop-docker.sh

DEBIAN=/data/local/dockerroot

run_chroot() {
    chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"
}

echo "Stopping containers..."
run_chroot bash -c 'docker stop $(docker ps -q) 2>/dev/null' 2>/dev/null

echo "Stopping dockerd..."
PID=$(run_chroot cat /var/run/docker.pid 2>/dev/null)
if [ -n "$PID" ]; then
    run_chroot kill "$PID" 2>/dev/null
    for i in $(seq 1 15); do
        run_chroot kill -0 "$PID" 2>/dev/null || break
        sleep 1
    done
fi
run_chroot killall containerd 2>/dev/null
killall containerd-shim-runc-v2 2>/dev/null
sleep 1

echo "Unmounting..."
# Lazy unmount everything under dockerroot (handles duplicates and busy mounts)
while mount | grep -q "on $DEBIAN"; do
    mount | grep "on $DEBIAN" | awk '{print $3}' | sort -r | while read m; do
        umount -l "$m" 2>/dev/null
    done
    sleep 1
done

# Detach all loop devices for docker.img (multiple can accumulate)
losetup -a | grep docker.img | cut -d: -f1 | while read dev; do
    losetup -d "$dev" 2>/dev/null
done

echo "Done."
