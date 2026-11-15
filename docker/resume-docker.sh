#!/system/bin/sh
# Start Docker, then start the containers that were running at pause
# Usage (as root): sh /data/local/docker-on-android/resume-docker.sh   (from the PC: adb shell su -c 'sh /data/local/docker-on-android/resume-docker.sh')
KALI=/data/local/nhsystem/kalifs
run() { root=$1; shift; chroot "$root" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root TERM=dumb "$@"; }

sh "$(dirname "$0")/start-docker.sh" || exit 1
ids=$(cat $KALI/tmp/paused-containers 2>/dev/null)
[ -n "$ids" ] && run $KALI docker start $ids
rm -f $KALI/tmp/paused-containers
echo "Resumed."
