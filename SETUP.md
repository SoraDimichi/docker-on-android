# Setup Guide

## Prerequisites

- Unlocked bootloader (use `miunlock` tool or official Mi Unlock Tool)
- OrangeFox recovery flashed
- ADB and fastboot on PC (`platform-tools` in PATH)

## 1. Flash ROM

1. Boot into OrangeFox: Volume Up + Power
2. Wipe: Format Data (type "yes") + Advanced Wipe (Dalvik, Cache, System, Vendor)
3. ADB sideload EvolutionX:
   ```
   adb sideload EvolutionX-16.0-XXXXXXXX-raphael-XX.X.X-Official.zip
   ```

## 2. Flash Magisk

1. Stay in OrangeFox after ROM flash
2. Rename Magisk APK to .zip
3. Start ADB sideload in OrangeFox
4. Sideload:
   ```
   adb sideload Magisk-vXX.X.zip
   ```
5. Reboot

## 3. Flash Antigravity Kernel

```bash
adb reboot bootloader
fastboot flash boot boot-raphael-docker-v1.0.img
fastboot reboot
```

Download: https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity/releases

## 4. Setup Termux + SSH

Install Termux from F-Droid, then:

```bash
pkg install openssh
sshd
passwd  # set password
```

Connect from PC: `ssh user@<phone-ip> -p 8022`

For key-based auth:
```bash
mkdir -p ~/.ssh
echo "<your-public-key>" > ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## 5. Create ext4 Image

```bash
su
dd if=/dev/zero of=/data/local/docker.img bs=1M count=8192
# Use Termux mkfs.ext4:
export PATH=/data/data/com.termux/files/usr/bin:$PATH
mkfs.ext4 /data/local/docker.img
mkdir -p /data/local/dockerroot
LOOPDEV=$(losetup -f)
losetup $LOOPDEV /data/local/docker.img
mount -t ext4 $LOOPDEV /data/local/dockerroot
```

## 6. Install Debian

```bash
# Download rootfs
curl -o /data/local/debian.tar.xz https://easycli.sh/proot-distro/debian-trixie-aarch64-pd-v4.37.0.tar.xz

# Extract
mkdir -p /data/local/debian
tar xf /data/local/debian.tar.xz -C /data/local/debian
mv /data/local/debian/debian-trixie-aarch64/* /data/local/debian/

# Copy to ext4 mount (unmount proc/sys/dev first if mounted)
cp -a /data/local/debian/* /data/local/dockerroot/
```

## 7. Mount Chroot Filesystems

```bash
setenforce 0

mount --bind /proc /data/local/dockerroot/proc
mount --bind /dev /data/local/dockerroot/dev
mkdir -p /data/local/dockerroot/dev/pts
mount --bind /dev/pts /data/local/dockerroot/dev/pts
mount --bind /sys /data/local/dockerroot/sys

# Cgroups
mkdir -p /data/local/dockerroot/sys/fs/cgroup
mount -t tmpfs tmpfs /data/local/dockerroot/sys/fs/cgroup

for cg in devices cpu blkio freezer pids; do
    mkdir -p /data/local/dockerroot/sys/fs/cgroup/$cg
    mount -t cgroup -o $cg cgroup /data/local/dockerroot/sys/fs/cgroup/$cg
done

mkdir -p /data/local/dockerroot/sys/fs/cgroup/memory
mount -t cgroup -o memory cgroup /data/local/dockerroot/sys/fs/cgroup/memory

# IMPORTANT: mount cpuset WITHOUT noprefix
mkdir -p /data/local/dockerroot/sys/fs/cgroup/cpuset
mount -t cgroup -o cpuset /data/local/dockerroot/sys/fs/cgroup/cpuset

echo "nameserver 8.8.8.8" > /data/local/dockerroot/etc/resolv.conf
chmod 1777 /data/local/dockerroot/tmp
```

## 8. Install Docker in Debian

```bash
chroot /data/local/dockerroot /usr/bin/env \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "apt update && apt install -y docker.io"
```

## 9. Start Docker

```bash
chroot /data/local/dockerroot /usr/bin/env \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "dockerd --iptables=false --storage-driver=vfs &>/tmp/dockerd.log &"

sleep 10
```

## 10. Test

```bash
chroot /data/local/dockerroot /usr/bin/env \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    docker run hello-world
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Devices cgroup isn't mounted` | Need Antigravity kernel, or cgroups not mounted in chroot |
| `remount /, flags: 0x84000: invalid argument` | Debian must be on ext4 loop device, not on /data directly |
| `cpuset/docker/cpuset.cpus: no such file` | Mount cpuset WITHOUT `noprefix` flag |
| `unexpected e_type: 2` | Static binary blocked by Android PIE enforcement — use chroot |
| Phone bootloop after disabling Google packages | Don't disable system overlays, launcher, webview, packageinstaller |
