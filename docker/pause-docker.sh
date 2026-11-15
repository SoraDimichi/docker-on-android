#!/system/bin/sh
# Remember the running containers, then stop Docker
# Usage (as root): sh /data/local/docker-on-android/pause-docker.sh   (from the PC: adb shell su -c 'sh /data/local/docker-on-android/pause-docker.sh')
KALI=/data/local/nhsystem/kalifs
run() { root=$1; shift; chroot "$root" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root TERM=dumb "$@"; }

run $KALI docker ps -q > $KALI/tmp/paused-containers 2>/dev/null
sh "$(dirname "$0")/stop-docker.sh"
echo "Paused. Resume with: sh /data/local/docker-on-android/resume-docker.sh"
