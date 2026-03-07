# Docker on Android (Mi 9T Pro / Redmi K20 Pro)

Running Docker on a rooted Android phone using a custom kernel + Debian chroot.

> Tested on Xiaomi Mi 9T Pro (Redmi K20 Pro / `raphael`), [EvolutionX](https://evolution-x.org/) 16.0, [Antigravity kernel](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) with Docker cgroup support.

## Device

- **Phone**: Xiaomi Mi 9T Pro / Redmi K20 Pro (codename: `raphael`)
- **SoC**: Snapdragon 855
- **RAM**: 6GB
- **Storage**: 128GB

## Stack

- **ROM**: [EvolutionX](https://evolution-x.org/) 16.0 (Android 16)
- **Kernel**: [Antigravity](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) v1.0.0 (4.14.353-openela-SOVIET-STAR) — enables Docker cgroup support (kernel with Docker support)
- **Root**: Magisk (flashed via OrangeFox recovery sideload)
- **Terminal**: Termux with SSH (port 8022)
- **Container**: Debian 13 (trixie) chroot on ext4 loop device
- **Docker**: docker.io from Debian repos, vfs storage driver

## Why each component is needed

| Component | Why |
|-----------|-----|
| Antigravity kernel | Stock kernel missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start |
| Debian chroot | Android userspace blocks static binaries (PIE enforcement) — Docker's `runc` won't run natively |
| ext4 loop device | Android's `/data` mounted with `nosuid,nodev` — Docker can't remount root filesystem |
| `--iptables=false` | Android's iptables setup conflicts with Docker networking — use `--network=host` for containers |
| `--storage-driver=vfs` | overlayfs remount fails on Android — vfs works as fallback |
| `mount -t cgroup -o cpuset` | Must mount WITHOUT `noprefix` flag, otherwise Docker can't find `cpuset.cpus` |

## Setup

See [SETUP.md](SETUP.md) for full step-by-step instructions.

## Quick Start

After initial setup, start Docker with:

```bash
su -c bash /data/data/com.termux/files/home/start-docker.sh
```

Enter Debian:

```bash
su -c "chroot /data/local/dockerroot /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash"
```

Run containers:

```bash
docker run hello-world
```

## Networking

Since Docker runs with `--iptables=false`, bridge networking and `-p` port mapping don't work. Use `--network=host` instead — containers bind directly to the phone's network:

```bash
# Run nginx, accessible from any device on the local network
docker run -d --network=host nginx

# Access from PC (replace with your phone's IP)
curl http://192.168.0.107:80
```

This was tested and confirmed working — nginx served from the phone is reachable from a PC on the same network.
