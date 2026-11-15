# 3. NetHunter Full for raphael

Kali NetHunter has two editions for this phone:

- **Lite**: the generic ARM64 zip. It has the NetHunter apps and the Kali chroot.
- **Full**: a zip for one device. It has everything from Lite, plus the kernel, the kernel modules, the firmware for USB Wi-Fi and Bluetooth adapters, and the `hid-keyboard` tool.

There is no official Full zip for `raphael`. This page builds one. It uses the kernel from [step 1](01-build-kernel.md): the same kernel that is in `boot-docker.img`. Then it installs the zip as a Magisk module.

> **Status (2026-11-15):** installed on the phone (VoltageOS 6.2, Android 17) as a Magisk module. The module is active, the apps are installed, the Kali chroot works, and the signed kernel modules load. See [Tested on the phone](#tested-on-the-phone).

## Versions

| Part | Version |
|------|---------|
| ROM | VoltageOS 6.2 (Android 17), `voltage-6.2-raphael-20261022-0545-OFFICIAL.zip` |
| Kernel | `4.14.357-Alchemy` `#1 SMP PREEMPT Sun Nov 15 09:31:10 CET 2026`, Clang 22.0.2, no root code. `Image.gz-dtb` SHA-256 `e624370e84987e19d24c424656d13df4e1348771caebb86d9a103eead751c0d2` |
| `boot-docker.img` | SHA-256 `79195988450669dcf9b57f507a6bf5c3a2faab09718cde12a44b49f25d3afe18` |
| Root | Magisk v31.1 |
| Installer scripts | [kali-nethunter-installer](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-installer) `main` at `aa1dca6` (2026-10-31) = tag `2026.3` + 5 commits |
| Device list | [kali-nethunter-kernels](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernels) `main` at `303ad0f`, only `devices.yml` |
| Apps | NetHunter `2026100700` (2026.3), NetHunter Terminal `2026010400`, KeX `11525001`, Store `2019030201`, Store privileged extension `2130` |
| Kali rootfs | `kali-nethunter-rootfs-full-arm64.tar.xz` (2026-10-24), 1837393488 bytes, SHA-256 `cc677eac68d6699873b1d617dda2957506665e71f9910923584248c80e1ec007` |
| Zip | `nethunter-2026.3-5-gaa1dca6-raphael-vos-seventeen-kalifs_full.zip`, 2111182825 bytes, SHA-256 `0d397f02d91a22785e5eed1ec0fc8a56468a1524b55fbf71befe73bc46529d17` |

The installer scripts are from `main`, not from the tag `2026.3`. The 2026.3 scripts copy the Kali rootfs archive (1.8 GB) into the module folder, and you had to delete it manually. The 5 later commits fix this. They also fix a new install over an old chroot (`dev/binderfs` unmount) and the `bootkali` links.

A new build of the same versions gives a zip with a different SHA-256, because the file dates in the zip change. The kernel, the modules and the rootfs in it stay the same.

## Build

### Requirements

- The kernel build of [step 1](01-build-kernel.md) is done: `boot-docker.img`, `modules/<kernel release>/` and the build folder `kernel-build/kernel/out/`.
- Packages: `sudo apt-get install git python3 python3-requests python3-yaml openssl unzip`.
- 8 GB free disk space. Do not use a folder in RAM (tmpfs), for example `/tmp` on WSL. The script stops if its folder is on tmpfs.
- Internet. The script downloads the installer scripts (about 55 MB), the apps (184 MB) and the Kali rootfs (1.8 GB).

### Command

From the repo root:

```bash
./nethunter/build-full.sh
```

Default folders: `nethunter-build/` in the repo for work and output (ignored by git), and the repo itself for the kernel. Change them with `WORK_DIR=<path>` and `DOA_DIR=<path>`.

The output is `nethunter-build/out/nethunter-2026.3-5-gaa1dca6-raphael-vos-seventeen-kalifs_full.zip`, with a `.sha256` file next to it. The first build took 2 minutes on a fast connection. A second build uses the downloaded files again.

Build the zip again after each new kernel build. The installer flashes the kernel of the zip (see [below](#what-the-installer-does-under-magisk)), so an old zip puts an old kernel on the phone.

### What the script does

1. It runs [`check-kernel.py`](../nethunter/check-kernel.py). This check confirms that the zip and `boot-docker.img` get the same kernel:
   - The kernel in `boot-docker.img` is byte-identical to `Image.gz-dtb`.
   - The kernel release in `Image.gz-dtb` (`4.14.357-Alchemy`) is the name of the modules folder.
   - Every module has the same `vermagic` and is signed with the key that is built into this kernel. The kernel has `MODULE_SIG_FORCE`, so it loads only these modules.
2. It downloads `kali-nethunter-installer` at the pinned commit to `nethunter-build/installer/`.
3. It downloads only `devices.yml` and `README.md` of `kali-nethunter-kernels` (sparse checkout) to `installer/kernels/`. The prebuilt kernels of other devices are not needed.
4. It adds the entry from [`raphael-vos.yml`](../nethunter/raphael-vos.yml) to `devices.yml`.
5. It copies the kernel and the modules into the layout that `build.py` expects:
   ```
   installer/kernels/seventeen/raphael-vos/Image.gz-dtb
   installer/kernels/seventeen/raphael-vos/modules/system_root/lib/modules/4.14.357-Alchemy/
   ```
6. It runs `python3 build.py --kernel raphael-vos --rootfs full --release 2026.3-5-gaa1dca6`. `build.py` downloads the apps and the rootfs and checks each download: the apps against the SHA-512 values in `build.py`, the rootfs against the published `SHA256SUMS`. A second build uses the downloaded files without a new check. The script prints the rootfs SHA-256 at the end, so you can compare it with the table above.
7. It checks the zip: no damaged data, the rootfs and the scripts are in it, and both kernel copies in it (`boot-patcher/Image.gz-dtb` and the one in `kernel-nethunter.zip`) are byte-identical to `Image.gz-dtb`.

### The devices.yml entry

```yaml
- raphael:
    model  : Xiaomi Mi 9T Pro / Redmi K20 Pro
    kernels:
      - id          : raphael-vos
        description : Xiaomi Mi 9T Pro / Redmi K20 Pro for VoltageOS, root with Magisk
        kernelstring: NetHunter kernel for Xiaomi Mi 9T Pro (VoltageOS 6.2)
        arch        : arm64
        block       : /dev/block/bootdevice/by-name/boot
        devicenames : raphael,raphaelin
        modules     : 0
        slot_device : 0
        versions    :
          - android    : seventeen
            linux      : 4.14
            description: VoltageOS 6.2 (Android 17)
            author     : SoraDimichi
            source     : 'git clone https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael -b 17 (built with docker-on-android kernel-build/build.sh)'
            features   : [HID-4, BT_RFCOMM, ATH9K_HTC, RT2800USB, MAC80211_HWSIM, USB_ACM, FTDI, CH341, CP210X, BTUSB, Docker]
```

About the entry:

- `id`: the codename, then `vos` for VoltageOS, as the README of kali-nethunter-kernels asks for a ROM that is not stock.
- `android: seventeen`: the name for Android 17. The names are the Android version in words: `fourteen`, `fifteen`, `sixteen`. At this commit, `build.py` has flags only up to `--sixteen`. The script gives no Android flag. Then `build.py` checks all folders `kernels/<name>/raphael-vos`, finds only `seventeen`, and uses it (log: `Auto selecting kernel image: seventeen`). No patch to `build.py` is needed.
- `modules: 0`: AnyKernel3 does not copy modules into `/system`. It is the safe value: with `modules: 1`, a recovery install writes into the system partition. The Magisk module install copies the modules in all cases (`push_modules` in `update-magisk`).
- `slot_device: 0` and `block`: raphael has one boot partition, without A/B slots. The AnyKernel3 script of this installer version finds the boot partition by itself and does not read these two values.
- `devicenames`: the values of `getprop ro.product.device`. The Full zip does not check them (`do.devicecheck=0`).
- `features`: text for the NetHunter web pages only. The list is the real content of this kernel.

## Install

### Order on a freshly flashed VoltageOS 6.2

1. Flash VoltageOS 6.2 and the kernel with Magisk root, and give adb root: [step 2](02-flash-rom-kernel-root.md).
2. Install the NetHunter Full zip as a Magisk module ([below](#install-the-zip)).
3. Reboot and open the NetHunter app once.

[SSH into Kali](04-ssh.md) needs the Kali chroot, so set it up after this step.

### What the installer does under Magisk

- It flashes the kernel of the zip with its AnyKernel3 patcher. This kernel is the same file as the kernel in `boot-docker.img`: the build stops if they are different. The patcher keeps the Magisk ramdisk and patches the kernel for Magisk again (`Magisk detected! Patching kernel so reflashing Magisk is not necessary...`).
- It copies the signed kernel modules into the module: `/system/lib/modules/4.14.357-Alchemy`.
- It installs the NetHunter apps. The NetHunter app then has new, empty app data: grant root again and open it once.
- It unpacks the Kali rootfs to `/data/local/nhsystem/kali-arm64`. An existing chroot is deleted first (see [Install again](#install-again)).

`RECOVERYMODE=false` is required. The patcher selects its target partition with `if $RECOVERYMODE; then` (`tools/ak3-core.sh`). The installer starts the patcher in a new shell (`tools/magic-flash.sh`), where this variable is not set. An empty variable counts as true, and the patcher then writes the recovery partition, not the boot partition.

### Install the zip

```bash
$ADB push nethunter-build/out/nethunter-2026.3-5-gaa1dca6-raphael-vos-seventeen-kalifs_full.zip /data/local/tmp/nethunter.zip
$ADB shell "su -c 'export RECOVERYMODE=false; magisk --install-module /data/local/tmp/nethunter.zip'"
$ADB shell su -c 'rm /data/local/tmp/nethunter.zip'
```

The install takes about 5 minutes. Most of the time is the rootfs: 1.8 GB of xz goes to `/data/local/nhsystem`. These lines in the output are important:

- `* NetHunter (Magisk)`
- `- Target Image: /dev/block/sde49`: the boot partition (`readlink -f /dev/block/by-name/boot`).
- `- Magisk detected! Patching kernel so reflashing Magisk is not necessary...`
- `Kali NetHunter is now installed!`

Check that the recovery partition did not change. The first line must print the same SHA-256 as the second:

```bash
$ADB shell su -c 'head -c 67108864 /dev/block/by-name/recovery | sha256sum'
sha256sum kernel-build/stock-6.2/recovery.img
```

Then reboot, open the NetHunter app, grant root when Magisk asks, and allow the storage access. Wait until the app ends its first setup: it copies its scripts and mounts the Kali chroot. The Kali chroot is `/data/local/nhsystem/kali-arm64` (link: `kalifs`).

The installer prints "Please UPDATE the NetHunter app via the NetHunter Store before RUNNING it". The zip already has NetHunter 2026.3, the newest version in the Store on 2026-11-15.

### Check after the reboot

```bash
$ADB shell uname -r                                                     # 4.14.357-Alchemy
$ADB shell magisk -v                                                    # 31.1:MAGISK:R
$ADB shell su -c 'ls /data/adb/modules/nethunter/system/lib/modules/'   # 4.14.357-Alchemy
$ADB shell su -c 'ls /system/etc/firmware/ath9k_htc/'                   # htc_7010-1.4.0.fw  htc_9271-1.4.0.fw
```

### Install again

A new install deletes the old Kali chroot (`rm -rf`) and unpacks a new one. Everything in Kali is lost: Docker, the SSH keys, your files. Set them up again after the install ([step 4](04-ssh.md), [step 5](05-docker.md)). The NetHunter app also loses its settings, for example SSH start at boot.

`/sdcard` is mounted inside the chroot. The installer unmounts it before the delete, with one lazy unmount. If `/sdcard` is mounted there two times, the delete goes into the phone's storage. So first stop everything that uses the chroot and unmount everything under it:

```bash
$ADB shell su -c 'sh /data/local/docker-on-android/stop-docker.sh'   # only if Docker is installed
$ADB shell su -c sh <<'EOF'
am force-stop com.offsec.nethunter
K=/data/local/nhsystem/kali-arm64
for p in /proc/[0-9]*; do case "$(readlink $p/root)" in $K*|/data/local/dockerroot*) kill -9 ${p#/proc/};; esac; done
for i in 1 2 3 4 5 6; do for m in $(grep " $K/" /proc/mounts | awk '{print $2}' | sort -r); do umount -l "$m"; done; done
echo "mounts left: $(grep -c " $K/" /proc/mounts)"
EOF
```

Install the zip only when the last line prints `mounts left: 0`.

### Kernel modules in Kali

The module puts the modules into `/system/lib/modules/4.14.357-Alchemy/`. Kali's `modprobe` reads `/lib/modules/<kernel release>/`, and the NetHunter app does not link the two folders. Copy the modules into the chroot once, from the module folder on `/data`:

```bash
$ADB shell su -c 'mkdir -p /data/local/nhsystem/kalifs/lib/modules && cp -r /data/adb/modules/nethunter/system/lib/modules/4.14.357-Alchemy /data/local/nhsystem/kalifs/lib/modules/'
```

Then, as root in Kali (`ssh kali` or NetHunter Terminal):

```bash
modprobe mac80211_hwsim radios=2   # two fake Wi-Fi radios
iw dev
modprobe ath9k_htc                 # Atheros AR9271 USB adapter, loads ath, ath9k_hw, ath9k_common first
```

Copy the modules again after each new kernel build.

### Firmware for USB adapters

The module adds the NetHunter firmware files to `/system/etc/firmware`. The kernel cannot read that folder directly. It asks Android's `ueventd`, which reads `/etc/firmware` (`FW_LOADER_USER_HELPER_FALLBACK=y`). If `dmesg` shows that a firmware file is not found, give the kernel the folder directly (Android root shell, until the next reboot):

```bash
echo -n /data/adb/modules/nethunter/system/etc/firmware > /sys/module/firmware_class/parameters/path
```

## Features with this kernel

The USB features in these tables are not tested on the phone yet.

### Supported by the kernel

| NetHunter feature | Kernel options | Notes |
|-------------------|----------------|-------|
| HID keyboard attacks, DuckHunter, USB Arsenal `hid` | `USB_CONFIGFS_F_HID` | The app makes `hid.0` (keyboard, `/dev/hidg0`) and `hid.1` (mouse, `/dev/hidg1`) in `/config/usb_gadget/g1` |
| USB Arsenal `rndis` (BadUSB) and `mass_storage` | `USB_CONFIGFS_RNDIS`, `USB_CONFIGFS_F_GSI`, `USB_CONFIGFS_MASS_STORAGE` | |
| USB Wi-Fi with Atheros AR9271, AR7010 | `MAC80211`, `ATH9K_HTC` (module) | Load the module first. The zip has the firmware `ath9k_htc/htc_9271-1.4.0.fw` |
| USB Wi-Fi with Ralink RT2770, RT2870, RT3070, RT3071, RT3072, RT3370, RT3572 | `RT2800USB`, `RT2800USB_RT33XX`, `RT2800USB_RT35XX` | The zip has the firmware `rt2870.bin` |
| Monitor mode and packet injection on these USB adapters | upstream `mac80211` | Without the NetHunter injection patch |
| Fake Wi-Fi radios for practice | `MAC80211_HWSIM` (module) | `modprobe mac80211_hwsim radios=2` |
| USB serial: Arduino, ESP32 boards, M5Stack Cardputer, Flipper Zero, UART adapters | `USB_ACM`, `USB_SERIAL_FTDI_SIO`, `USB_SERIAL_CH341`, `USB_SERIAL_CP210X` | `/dev/ttyACM*`, `/dev/ttyUSB*` |
| Bluetooth Arsenal with a USB Bluetooth adapter | `BT_RFCOMM`, `BT_RFCOMM_TTY`, `BT_HCIBTUSB` | Realtek adapters: this kernel knows RTL8723A, RTL8723B, RTL8821A, RTL8761A and RTL8822B |
| USB Ethernet adapters | `USB_RTL8152`, `USB_NET_AX88179_178A`, `USB_NET_CDCETHER` | From the VoltageOS defconfig |
| OpenVPN and other VPNs in Kali | `TUN` | |
| Docker | [`docker.config`](../kernel-build/docker.config) | [Step 5](05-docker.md) |

### Not supported by the kernel

| Feature | Missing in the kernel |
|---------|-----------------------|
| Monitor mode on the internal Wi-Fi | QCACLD monitor-mode patch |
| NetHunter Wi-Fi injection patch | Not applied. Only the upstream `mac80211` injection code is there |
| Realtek USB Wi-Fi: RTL8812AU, RTL8814AU, RTL8821AU, RTL8188EUS | No driver (`RTL8XXXU` is off, no out-of-tree drivers) |
| Ralink RT3573, RT5370, RT5372, RT5572 | `RT2800USB_RT3573`, `RT2800USB_RT53XX`, `RT2800USB_RT55XX` |
| MediaTek MT7601U and MT76, Realtek RTL8187, carl9170 | No driver. The zip has firmware for some of them, but firmware without a driver does nothing |
| USB Arsenal `acm` and `ecm` | `USB_CONFIGFS_ACM`, `USB_CONFIGFS_ECM` |
| Internal Bluetooth in Kali | `BT_HCIVHCI`, `BT_HCIUART` |
| Bluetooth HID and PAN | `BT_HIDP`, `BT_BNEP` |
| NFS client and server | `NFS_FS`, `NFSD` |
| CAN (CARsenal) | `CAN` |
| Nexmon | Only for Broadcom Wi-Fi chips. This phone has a Qualcomm chip |

To add a missing feature: add the option to [`kernel-build/nethunter.config`](../kernel-build/nethunter.config), build the kernel, patch and flash the new `boot-docker.img` ([step 2](02-flash-rom-kernel-root.md)), then build and install this zip again.

## Verified on the PC

- The kernel in the zip (both copies) is byte-identical to the kernel in `boot-docker.img`: `4.14.357-Alchemy`.
- All 8 modules in the zip have `vermagic=4.14.357-Alchemy` and are signed with the key that is built into this kernel.
- The zip has no damaged data (`unzip -t`). The rootfs entry is stored, not compressed again. The zip is smaller than 2 GiB and has no ZIP64 records.
- The rootfs matches the published SHA-256. The apps match the SHA-512 values in `build.py`.
- The scripts in the zip: `customize.sh` has `SKIPUNZIP=1` and does not unpack `kalifs-*`. Under Magisk, `update-magisk` flashes the kernel of the zip (`do_flash`, then `tools/magic-flash.sh`). `push_modules` finds the folder `boot-patcher/modules/system_root/lib/modules/4.14.357-Alchemy`.

## Tested on the phone

On 2026-11-15, on VoltageOS 6.2 (Android 17) with Magisk v31.1:

- `magisk --install-module` of this zip with `RECOVERYMODE=false` ended with exit code 0. After the reboot, the module `nethunter` 1.4.0 is active and Magisk still works.
- The patcher wrote the boot partition. The recovery partition did not change.
- An install over an old chroot deleted it and unpacked a new one. `/sdcard` kept its files.
- The 5 apps are installed: NetHunter 2026.3, NetHunter Terminal 2025.4, KeX v5.2.5-1, Store 2019.3b and the Store privileged extension 0.2.13-nethunter.
- `insmod` of the signed `mac80211_hwsim.ko` worked, and `rmmod` worked too.
- NetHunter's SSH service (Kali Services) starts Kali's `sshd`, also at boot ([step 4](04-ssh.md)).

Not tested yet:

- `modprobe` in Kali, and firmware loading for USB Wi-Fi adapters through `ueventd`.
- HID, RNDIS and mass storage gadgets with the NetHunter app.
- The internal Wi-Fi and Bluetooth with the NetHunter firmware files in `/system/etc/firmware`. The files are for USB adapters. A name conflict with the phone firmware is not expected, but it is not checked.
- The recovery install of the zip. Do not use it.

## Known problems

- NetHunter app 2026.3: the switch in Kali Services crashes the app (`ConcurrentModificationException` in `KaliServicesExecutor`). The service starts anyway. The app can also crash when you come back to it (`RejectedExecutionException` in `CopyBootFilesExecutor`). Open it again.
- When the process of the NetHunter app ends, the kernel logs a warning: `mem_cgroup_update_lru_size ... lru_size -1`. The cause is not known. With KernelSU-Next instead of Magisk, the phone also reset itself when apps used root. With Magisk, no reset was seen.

## Problems and removal

- If Android does not start after the install: start Android in safe mode (hold Volume Down while the boot animation shows). Magisk then turns off all modules. Remove the module, then reboot.
- Remove NetHunter: first remove the chroot in the NetHunter app (Kali Chroot Manager). Then run `$ADB shell su -c 'touch /data/adb/modules/nethunter/remove'` (or Magisk → Modules → Remove), reboot, and uninstall the apps (`$ADB uninstall com.offsec.nethunter`, and the same for `com.offsec.nhterm`, `com.offsec.nethunter.kex`, `com.offsec.nethunter.store`, `com.offsec.nethunter.store.privileged`).

## Notes

- Like the Lite zip, the installer sets the NetHunter wallpaper and boot animation.
- The NetHunter app sets SELinux to Permissive each time it starts. Check with `getenforce`. `su -c 'setenforce 1'` sets Enforcing again, and Kali still works.
- Never delete the chroot with `rm -rf` while it runs. `/sdcard` is mounted inside it, and the delete wipes the phone's storage.
