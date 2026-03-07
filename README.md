# Docker on Android (Mi 9T Pro)

> **WARNING: This guide involves unlocking the bootloader, flashing custom ROMs, custom kernels, and rooting your device. Any of these steps can brick your phone. There are no guarantees. Proceed at your own risk.**

**Requires an unlocked bootloader.** Without it, you cannot flash custom ROMs or kernels.

Running Docker on a rooted Android phone using a custom kernel + Debian chroot.

> Tested on Xiaomi Mi 9T Pro (Redmi K20 Pro / `raphael`), [VoltageOS](https://voltage-os.com/) 5.6 (Android 16), custom kernel with Docker cgroup support.

## Guides

| # | Guide | What |
|---|-------|------|
| 1 | [Build Kernel](1-BUILD.md) | Build VoltageOS kernel with Docker cgroup support + KernelSU-Next |
| 2 | [Flash ROM + Kernel](2-FLASH.md) | Flash VoltageOS and the custom kernel |
| 3 | [Termux + SSH](3-TERMUX.md) | SSH access, auto-start sshd on boot |
| 4 | [Docker](4-DOCKER.md) | Install, run, and manage Docker containers |

## Stack

| Component | Why |
|-----------|-----|
| Custom VoltageOS kernel ([build guide](1-BUILD.md)) | Stock kernel missing `CONFIG_CGROUP_DEVICE` — Docker refuses to start |
| [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) v1.0.8 | Kernel-level root — no Magisk needed |
| Debian chroot on ext4 loop device | Android blocks static binaries (PIE) and `/data` has `nosuid,nodev` |
| `--iptables=false` + `--network=host` | Android iptables conflicts with Docker — bridge networking won't work |
| `--storage-driver=vfs` | overlayfs remount fails on Android |
| Skip cpuset cgroup | Android mounts cpuset with `noprefix` (kernel caches it) — Docker works without it |

## Setup

Follow the guides in order:

1. **[Build Kernel](1-BUILD.md)** — build `boot-docker.img` on a Linux PC (~30 min, ~10 GB disk)
2. **[Flash ROM + Kernel](2-FLASH.md)** — flash VoltageOS + custom kernel + install KernelSU-Next Manager
3. **[Termux + SSH](3-TERMUX.md)** — install Termux, set up SSH access from PC
4. **[Docker](4-DOCKER.md)** — install Debian chroot + Docker, run containers
