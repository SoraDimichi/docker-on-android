#!/system/bin/sh
# Stop all containers and dockerd
# Usage (as root): sh /data/local/docker-on-android/stop-docker.sh   (from the PC: adb shell su -c 'sh /data/local/docker-on-android/stop-docker.sh')
# The private mount namespace goes away with dockerd, so nothing needs unmounting.
KALI=/data/local/nhsystem/kalifs
run() { root=$1; shift; chroot "$root" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root TERM=dumb "$@"; }

run $KALI /bin/bash -c 'ids=$(docker ps -q); [ -n "$ids" ] && docker stop $ids' 2>/dev/null
for name in dockerd containerd; do
  pids=$(ps -A -o PID,NAME | grep " $name\$" | awk '{print $1}')
  [ -n "$pids" ] && kill $pids
done
i=0
while [ $i -lt 15 ] && ps -A -o NAME | grep -qE '^(dockerd|containerd)$'; do i=$((i + 1)); sleep 1; done
echo "Docker processes left: $(ps -A -o NAME | grep -cE '^(dockerd|containerd)$')"
