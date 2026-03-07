# Docker on Android (Mi 9T Pro)

Running Docker on a rooted Android phone using a custom kernel + Debian chroot.

> Tested on Xiaomi Mi 9T Pro (Redmi K20 Pro / `raphael`), [EvolutionX](https://evolution-x.org/) 16.0, [Antigravity kernel](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) with Docker cgroup support.

## Stack

| Component | Why |
|-----------|-----|
| [Antigravity kernel](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) | Stock kernel missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start |
| Debian chroot on ext4 loop device | Android blocks static binaries (PIE) and `/data` has `nosuid,nodev` |
| `--iptables=false` + `--network=host` | Android iptables conflicts with Docker — bridge networking won't work |
| `--storage-driver=vfs` | overlayfs remount fails on Android |
| `mount -t cgroup -o cpuset` (no `noprefix`) | Docker expects `cpuset.cpus`, not `cpus` |

## Setup

See [SETUP.md](SETUP.md).

## Quick Start

```bash
# One-time setup (creates image, installs Debian + Docker)
su -c bash ~/setup.sh

# Start Docker (after every reboot)
su -c bash ~/start-docker.sh
```

Enter chroot and run nginx:

```bash
su -c "chroot /data/local/dockerroot /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash"
docker run -d --network=host nginx:alpine
```

Access from PC: `curl http://<phone-ip>:80`

Uninstall (safe unmount + delete):

```bash
su -c bash ~/uninstall.sh
```
