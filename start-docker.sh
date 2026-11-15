#!/system/bin/sh
# Start dockerd for the Kali chroot (after every reboot)
# Usage (as root): sh /data/local/docker-on-android/start-docker.sh   (from the PC: adb shell su -c 'sh /data/local/docker-on-android/start-docker.sh')
# dockerd runs in its own private mount namespace, because:
# - pivot_root fails when the mount above the root is shared, and /data is shared on Android.
# - its cgroup mounts must not reach the real /sys/fs/cgroup of Android.
# /data/local/dockerroot looks empty outside that namespace. Inside it, it IS Kali: never delete it from there.
KALI=/data/local/nhsystem/kalifs
run() { root=$1; shift; chroot "$root" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root TERM=dumb "$@"; }
D=/data/local/dockerroot
BB=/system/bin/busybox_nh

if [ "$1" != inner ]; then
  if run $KALI docker info >/dev/null 2>&1; then
    echo "dockerd already running"
    exit 0
  fi
  exec unshare -m sh "$0" inner
fi

$BB mount --make-rprivate / || exit 1
mkdir -p $D
mount --bind $KALI $D || exit 1
mount --bind /proc $D/proc
mount --bind /dev $D/dev
mkdir -p $D/dev/pts
mount --bind /dev/pts $D/dev/pts
mount --bind /sys $D/sys
mount -t tmpfs tmpfs $D/sys/fs/cgroup
# cpuset is skipped: Android mounts it with noprefix (the kernel keeps that for every mount), and Docker then fails.
# memory is skipped: the kernel refuses a second mount, and Docker works without it.
for cg in devices cpu blkio freezer pids; do
  mkdir -p $D/sys/fs/cgroup/$cg
  mount -t cgroup -o $cg cgroup $D/sys/fs/cgroup/$cg
done
chmod 1777 $D/tmp

# GODEBUG=netdns=cgo: Go's own DNS resolver fails on Android
run $D /bin/bash -c "GODEBUG=netdns=cgo nohup dockerd --iptables=false --ip6tables=false --storage-driver=vfs >/tmp/dockerd.log 2>&1 </dev/null &"

# Android policy routing sends 172.17.x.x out over Wi-Fi. Keep it on docker0.
ip rule del pref 9000 2>/dev/null
ip rule del pref 9001 2>/dev/null
ip rule add to 172.17.0.0/16 lookup main pref 9000
ip rule add from 172.17.0.0/16 lookup main pref 9001

# Bridge containers get no NAT (--iptables=false), and LAN devices must not reach them through the phone.
# Published ports (-p) still work, because docker-proxy is a local process. Use --network=host for internet access.
iptables -C FORWARD -o docker0 -j DROP 2>/dev/null || iptables -I FORWARD -o docker0 -j DROP
iptables -C FORWARD -i docker0 -j DROP 2>/dev/null || iptables -I FORWARD -i docker0 -j DROP

i=0
while [ $i -lt 30 ]; do
  run $D docker info >/dev/null 2>&1 && { echo "dockerd ready after $i s"; exit 0; }
  i=$((i + 1))
  sleep 1
done
echo "dockerd did not start, see /tmp/dockerd.log in Kali"
tail -n 15 $D/tmp/dockerd.log
exit 1
