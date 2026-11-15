#!/system/bin/sh
# Remove Docker from the Kali chroot. Kali itself stays.
# Usage (as root): sh /data/local/docker-on-android/uninstall.sh   (from the PC: adb shell su -c 'sh /data/local/docker-on-android/uninstall.sh')
KALI=/data/local/nhsystem/kalifs
run() { root=$1; shift; chroot "$root" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root TERM=dumb "$@"; }
D=/data/local/dockerroot

if [ "$1" != inner ]; then
  exec unshare -m sh "$0" inner
fi

sh "$(dirname "$0")/stop-docker.sh"
if ps -A -o NAME | grep -qE '^(dockerd|containerd)$'; then
  echo "Error: dockerd still runs, aborting."
  exit 1
fi

/system/bin/busybox_nh mount --make-rprivate / || exit 1
mount --bind /proc $KALI/proc
mount --bind /dev $KALI/dev
run $KALI /bin/bash -c "export DEBIAN_FRONTEND=noninteractive; apt-get purge -y docker.io docker-cli && apt-get autoremove -y"
rm -rf $KALI/var/lib/docker $KALI/var/lib/containerd

# rmdir, not rm -rf: inside a running start-docker.sh namespace this folder is Kali itself
rmdir $D 2>/dev/null
# Image of the old Debian-based setup of this project
[ -f /data/local/docker.img ] && rm -f /data/local/docker.img && echo "Removed the old /data/local/docker.img"
echo "Uninstalled. Kali stays at $KALI."
