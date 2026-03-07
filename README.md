# Docker on Android (Mi 9T Pro)

> **WARNING: This guide involves unlocking the bootloader, flashing custom ROMs, custom kernels, and rooting your device. Any of these steps can brick your phone. You are flashing a kernel built by a random guy on GitHub. There are no guarantees. Proceed at your own risk.**

## Download

Pre-built `boot-docker.img` is available on the [Releases](https://github.com/SoraDimichi/docker-on-android/releases) page. To build from source, see [Build Kernel](docs/4-KERNEL.md).

Running Docker on a rooted Android phone using a custom kernel + Debian chroot.

> Tested on Xiaomi Mi 9T Pro (Redmi K20 Pro / `raphael`), [VoltageOS](https://voltage-os.com/) 5.6 (Android 16), custom kernel with Docker cgroup support.

## Guides

| # | Guide | What |
|---|-------|------|
| 1 | [Flash ROM + Kernel](docs/1-FLASH.md) | VoltageOS, custom kernel, KernelSU-Next |
| 2 | [Termux + SSH](docs/2-TERMUX.md) | SSH access, auto-start sshd on boot |
| 3 | [Docker](docs/3-DOCKER.md) | Install, run, and manage Docker containers |
| 4 | [Build Kernel](docs/4-KERNEL.md) | Build VoltageOS kernel with Docker cgroup support |

## Stack

| Component | Why |
|-----------|-----|
| Custom VoltageOS kernel ([build guide](docs/4-KERNEL.md)) | Stock kernel missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start |
| [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) v1.0.8 | Kernel-level root — no Magisk needed |
| Debian chroot on ext4 loop device | Android blocks static binaries (PIE) and `/data` has `nosuid,nodev` |
| `--iptables=false` + `--network=host` | Android iptables conflicts with Docker — bridge networking won't work |
| `--storage-driver=vfs` | overlayfs remount fails on Android |
| Skip cpuset cgroup | Android mounts cpuset with `noprefix` (kernel caches it) — Docker works without it |

## Quick Start

```bash
su -c bash ~/setup.sh        # one-time
su -c bash ~/start-docker.sh  # after every reboot
```

Enter chroot and run nginx:

```bash
su -c "chroot /data/local/dockerroot /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash"
docker run -d --network=host nginx:alpine
```

Access from PC: `curl http://<phone-ip>:80`

## Scripts

| Script | What it does | When to use |
|--------|-------------|-------------|
| `setup.sh` | Create ext4 image, install Debian + Docker | First time only |
| `start-docker.sh` | Mount everything + start dockerd | After reboot |
| `stop-docker.sh` | Graceful shutdown + unmount + detach loop | Full teardown |
| `pause-docker.sh` | Stop all containers + stop dockerd (mounts stay) | Save battery, free resources |
| `resume-docker.sh` | Start dockerd + restart all containers | Wake up where you left off |
| `uninstall.sh` | Stop, unmount, delete image + chroot | Remove everything |

All scripts: `su -c bash ~/script.sh`
