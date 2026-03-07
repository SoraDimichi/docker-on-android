# Setup

## Prerequisites

- Unlocked bootloader
- ADB and fastboot on PC

## 1. Flash ROM + Magisk

1. Boot into recovery: Volume Up + Power
2. Wipe: Format Data ("yes") + Advanced Wipe (Dalvik, Cache, System, Vendor)
3. ADB sideload EvolutionX (recovery included with the ROM):
   `adb sideload EvolutionX-16.0-XXXXXXXX-raphael-XX.X.X-Official.zip`
4. Rename Magisk APK to .zip, sideload: `adb sideload Magisk-vXX.X.zip`
5. Reboot

## 2. Flash Antigravity Kernel

Download from [releases](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity/releases).

```bash
adb reboot bootloader
fastboot flash boot boot-raphael-docker-v1.0.img
fastboot reboot
```

## 3. Setup Termux + SSH

Install Termux from F-Droid:

```bash
pkg install openssh
sshd
passwd
```

Connect: `ssh user@<phone-ip> -p 8022`

## 4. Create ext4 Image + Install Debian

```bash
su
dd if=/dev/zero of=/data/local/docker.img bs=1M count=8192
export PATH=/data/data/com.termux/files/usr/bin:$PATH
mkfs.ext4 /data/local/docker.img
mkdir -p /data/local/dockerroot
LOOPDEV=$(losetup -f)
losetup $LOOPDEV /data/local/docker.img
mount -t ext4 $LOOPDEV /data/local/dockerroot

curl -o /data/local/debian.tar.xz https://easycli.sh/proot-distro/debian-trixie-aarch64-pd-v4.37.0.tar.xz
mkdir -p /data/local/debian
tar xf /data/local/debian.tar.xz -C /data/local/debian
mv /data/local/debian/debian-trixie-aarch64/* /data/local/debian/
cp -a /data/local/debian/* /data/local/dockerroot/
```

## 5. Install Docker + Test

```bash
# Mount, install, start (use start-docker.sh after first setup)
setenforce 0
# ... mount filesystems (see start-docker.sh) ...

chroot /data/local/dockerroot /usr/bin/env \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    bash -c "apt update && apt install -y docker.io"

# Test
docker run -d --network=host nginx:alpine
curl http://localhost:80
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Devices cgroup isn't mounted` | Need Antigravity kernel, or cgroups not mounted |
| `remount /, flags: 0x84000` | Must use ext4 loop device, not /data directly |
| `cpuset/docker/cpuset.cpus: no such file` | Mount cpuset WITHOUT `noprefix` |
| `-p` port mapping not working | Use `--network=host` instead |
