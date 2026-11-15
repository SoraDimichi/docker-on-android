#!/system/bin/sh
# Start the SSH server of the Kali chroot at boot. KernelSU runs this file from /data/adb/service.d.
# A root process started here belongs to no app, so Android does not kill it together with an app.
# It runs in a private mount namespace, so its mounts never reach Android or the NetHunter app.
KALI=/data/local/nhsystem/kalifs
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
# Keep the CPU awake, so that SSH answers when the screen is off (Termux used termux-wake-lock for this)
echo kali-sshd > /sys/power/wake_lock
unshare -m /system/bin/sh -c "
  /system/bin/busybox_nh mount --make-rprivate /
  mount --bind /proc $KALI/proc
  mount --bind /dev $KALI/dev
  mount --bind /dev/pts $KALI/dev/pts
  mount --bind /sys $KALI/sys
  mkdir -p $KALI/run/sshd
  [ -f $KALI/etc/ssh/ssh_host_ed25519_key ] || chroot $KALI /usr/bin/ssh-keygen -A
  chroot $KALI /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root LANG=C.UTF-8 /usr/sbin/sshd
"
