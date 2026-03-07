#!/data/data/com.termux/files/usr/bin/bash
# Usage: su -c bash ~/resume-docker.sh

DEBIAN=/data/local/dockerroot

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

echo "Starting containers..."
run_chroot bash -c 'docker start $(cat /tmp/paused-containers) 2>/dev/null' 2>/dev/null
run_chroot rm -f /tmp/paused-containers

echo "Resumed."
