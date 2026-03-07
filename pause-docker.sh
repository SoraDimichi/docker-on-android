#!/data/data/com.termux/files/usr/bin/bash
# Usage: su -c bash ~/pause-docker.sh

DEBIAN=/data/local/dockerroot

run_chroot() {
    chroot $DEBIAN /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"
}

echo "Stopping containers..."
run_chroot bash -c 'docker ps -q > /tmp/paused-containers 2>/dev/null' 2>/dev/null
run_chroot bash -c 'docker stop $(cat /tmp/paused-containers) 2>/dev/null' 2>/dev/null

echo "Stopping dockerd..."
PID=$(run_chroot cat /var/run/docker.pid 2>/dev/null)
if [ -n "$PID" ]; then
    run_chroot kill "$PID" 2>/dev/null
    for i in $(seq 1 15); do
        run_chroot kill -0 "$PID" 2>/dev/null || break
        sleep 1
    done
fi

echo "Paused. Resume with: su -c bash ~/resume-docker.sh"
