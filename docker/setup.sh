#!/system/bin/sh
# One-time setup: install Docker in the Kali chroot of Kali NetHunter
# Usage (as root): sh /data/local/docker-on-android/setup.sh   (from the PC: adb shell su -c 'sh /data/local/docker-on-android/setup.sh')
KALI=/data/local/nhsystem/kalifs
run() { root=$1; shift; chroot "$root" /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root TERM=dumb "$@"; }

[ -x $KALI/bin/bash ] || { echo "Error: no Kali chroot at $KALI. Install Kali NetHunter first."; exit 1; }

# The bind mounts live in a private mount namespace: they never reach Android or the NetHunter app
if [ "$1" != inner ]; then
  exec unshare -m sh "$0" inner
fi
/system/bin/busybox_nh mount --make-rprivate / || exit 1
mount --bind /proc $KALI/proc
mount --bind /dev $KALI/dev
mkdir -p $KALI/dev/pts
mount --bind /dev/pts $KALI/dev/pts
mount --bind /sys $KALI/sys
grep -q '^nameserver' $KALI/etc/resolv.conf 2>/dev/null || { rm -f $KALI/etc/resolv.conf; echo "nameserver 8.8.8.8" > $KALI/etc/resolv.conf; }

run $KALI /bin/bash -c "export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get install -y docker.io docker-cli" || exit 1

echo ""
echo "Setup complete. Start Docker with:"
echo "  sh /data/local/docker-on-android/start-docker.sh"
