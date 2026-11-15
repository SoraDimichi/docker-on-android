# Mi 9T Pro: root, Kali NetHunter and Docker on Android

> **WARNING: This guide involves unlocking the bootloader, flashing custom ROMs, custom kernels, and rooting your device. Any of these steps can brick your phone. There are no guarantees. Proceed at your own risk.**

**Requires an unlocked bootloader.** Without it, you cannot flash custom ROMs or kernels.

A step-by-step setup for the Xiaomi Mi 9T Pro (Redmi K20 Pro, `raphael`) with [VoltageOS](https://voltage-os.com/): a custom kernel, root with [Magisk](https://github.com/topjohnwu/Magisk), [Kali NetHunter](https://www.kali.org/docs/nethunter/) Full, SSH into Kali, and Docker in the Kali chroot.

> Tested on VoltageOS 6.2 (Android 17) on 2026-11-15: the kernel, Magisk root, the NetHunter Full zip, SSH into Kali, Docker, NFC and the cameras.

## Steps

Do the steps in this order. Each step needs the steps before it.

| # | Guide | Where | Result |
|---|-------|-------|--------|
| 1 | [Build the kernel](docs/01-build-kernel.md) | Linux PC | `boot-docker.img`: VoltageOS kernel with Docker cgroups and NetHunter options |
| 2 | [Flash ROM, kernel and root](docs/02-flash-rom-kernel-root.md) | Phone and PC | VoltageOS, the custom kernel, Magisk root |
| 3 | [NetHunter Full](docs/03-nethunter.md) | PC, then phone | The NetHunter apps and a full Kali chroot |
| 4 | [SSH into Kali](docs/04-ssh.md) | Phone and PC | `ssh kali`: a root shell in Kali, started at boot |
| 5 | [Docker](docs/05-docker.md) | Phone | Docker in the Kali chroot |
| 6 | [Apps](docs/06-apps.md) | Phone | APKs, ACC charge limit |

## Stack

| Component | Why |
|-----------|-----|
| Custom VoltageOS kernel ([build guide](docs/01-build-kernel.md)) | The stock kernel has no `CONFIG_CGROUP_DEVICE` and `CONFIG_CGROUP_PIDS`, and Docker refuses to start |
| Clean kernel source, built with Clang 22 | No source patches. Clang 22.0.2 (r596125) is the compiler of the VoltageOS kernel itself |
| Device tree built with `dtc -H epapr` | Only `phandle` properties, like the VoltageOS build. With `linux,phandle` too, NFC and a camera fail |
| [Magisk](https://github.com/topjohnwu/Magisk) v31.1 | Root without code in the kernel. With KernelSU-Next in this kernel, the phone reset itself when apps used root |
| NetHunter kernel options ([`nethunter.config`](kernel-build/nethunter.config)) | USB Wi-Fi adapters, USB serial devices, USB Bluetooth dongles, and fake Wi-Fi radios for practice (`mac80211_hwsim`) |
| Kali NetHunter Full, built for raphael ([`nethunter/`](nethunter/)) | The NetHunter apps and a full Kali chroot. There is no official Full zip for raphael |
| Kali's own `sshd`, started by the NetHunter app | NetHunter's Kali Services start it at boot. A Magisk boot script holds a wake lock, so SSH answers when the screen is off |
| Docker in the Kali chroot | Kali is based on Debian, so no second Linux system is needed |
| `dockerd` in its own mount namespace | `pivot_root` fails under Android's shared `/data` mount |
| `--iptables=false` + `ip rule` for `172.17.0.0/16` | Docker must not change Android's iptables. Published ports (`-p`) work; bridge containers get no NAT |
| `--storage-driver=vfs` | overlayfs remount fails on Android |
| No `cpuset` and `memory` cgroups for Docker | Android mounts cpuset with `noprefix` (the kernel keeps it), and the kernel refuses a second memory mount. Docker works without both |

## Repo layout

| Path | Content |
|------|---------|
| [`docs/`](docs/) | The 6 guides, and the [inventory](docs/inventory/) of apps and system apps |
| [`kernel-build/`](kernel-build/) | Kernel build: `build.sh`, config fragments, the VoltageOS ramdisk |
| [`nethunter/`](nethunter/) | Build of the NetHunter Full zip |
| [`docker/`](docker/) | Docker scripts for the phone |
| [`config/`](config/) | Config files for the phone and the PC: SSH, wake lock, ACC |
| [`apks/`](apks/) | Folder for the APKs of [`download-apks.sh`](download-apks.sh). Git keeps only the empty folder |

Build outputs stay out of git: `boot-docker.img`, `modules/`, `nethunter-build/`, the kernel source, the toolchain and the stock images.

## Not in this repo

Secrets stay out of this repo: SSH private keys and passwords.
