# 3. NetHunter Full for raphael

Kali NetHunter has two editions for this phone:

- **Lite**: the generic ARM64 zip. It has the NetHunter apps and the Kali chroot.
- **Full**: a zip for one device. It has everything from Lite, plus the kernel, the kernel modules, the firmware for USB Wi-Fi and Bluetooth adapters, and the `hid-keyboard` tool.

There is no official Full zip for `raphael`. This page builds one. It uses the kernel from [step 1](01-build-kernel.md): the same kernel that is in `boot-docker.img`. Then it installs the zip as a KernelSU module.

> **Status (2026-11-15):** installed on the phone (VoltageOS 6.2, Android 17) as a KernelSU module. The module is active, the apps are installed, the Kali chroot works, and the signed kernel modules load. See [Tested on the phone](#tested-on-the-phone).

## Versions

| Part | Version |
|------|---------|
| ROM | VoltageOS 6.2 (Android 17), `voltage-6.2-raphael-20261022-0545-OFFICIAL.zip` |
| Kernel | `4.14.357-Alchemy` `#2 SMP PREEMPT Sun Nov 15 04:35:37 CET 2026`, with KernelSU-Next v1.1.1. `Image.gz-dtb` SHA-256 `896a2f77b8fc5f81a90a9c8195272d7b8eece30a3c501c0904224c579ed7cc6e` |
| `boot-docker.img` | SHA-256 `9a11683f61539a75dd9912b3388d299f543cb6aff6cb8a9834d2d8efa7f2a3b2` |
| Installer scripts | [kali-nethunter-installer](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-installer) `main` at `aa1dca6` (2026-10-31) = tag `2026.3` + 5 commits |
| Device list | [kali-nethunter-kernels](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-kernels) `main` at `303ad0f`, only `devices.yml` |
| Apps | NetHunter `2026100700` (2026.3), NetHunter Terminal `2026010400`, KeX `11525001`, Store `2019030201`, Store privileged extension `2130` |
| Kali rootfs | `kali-nethunter-rootfs-full-arm64.tar.xz` (2026-10-24), 1837393488 bytes, SHA-256 `cc677eac68d6699873b1d617dda2957506665e71f9910923584248c80e1ec007` |
| Zip | `nethunter-2026.3-5-gaa1dca6-raphael-vos-ksu-seventeen-kalifs_full.zip`, 2111322889 bytes, SHA-256 `5ec5e0004ae8cc200656ef0276f39a0b7665c51043931536e92cb175f84b901e` |

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

The output is `nethunter-build/out/nethunter-2026.3-5-gaa1dca6-raphael-vos-ksu-seventeen-kalifs_full.zip`, with a `.sha256` file next to it. The first build took 2 minutes on a fast connection. A second build uses the downloaded files again.

### What the script does

1. It runs [`check-kernel.py`](../nethunter/check-kernel.py). This check confirms that the zip and `boot-docker.img` get the same kernel:
   - The kernel in `boot-docker.img` is byte-identical to `Image.gz-dtb`.
   - The kernel release in `Image.gz-dtb` (`4.14.357-Alchemy`) is the name of the modules folder.
   - Every module has the same `vermagic` and is signed with the key that is built into this kernel. The kernel has `MODULE_SIG_FORCE`, so it loads only these modules.
2. It downloads `kali-nethunter-installer` at the pinned commit to `nethunter-build/installer/`.
3. It downloads only `devices.yml` and `README.md` of `kali-nethunter-kernels` (sparse checkout) to `installer/kernels/`. The prebuilt kernels of other devices are not needed.
4. It adds the entry from [`raphael-vos-ksu.yml`](../nethunter/raphael-vos-ksu.yml) to `devices.yml`.
5. It copies the kernel and the modules into the layout that `build.py` expects:
   ```
   installer/kernels/seventeen/raphael-vos-ksu/Image.gz-dtb
   installer/kernels/seventeen/raphael-vos-ksu/modules/system_root/lib/modules/4.14.357-Alchemy/
   ```
6. It runs `python3 build.py --kernel raphael-vos-ksu --rootfs full --release 2026.3-5-gaa1dca6`. `build.py` downloads the apps and the rootfs and checks each download: the apps against the SHA-512 values in `build.py`, the rootfs against the published `SHA256SUMS`. A second build uses the downloaded files without a new check. The script prints the rootfs SHA-256 at the end, so you can compare it with the table above.
7. It checks the zip: no damaged data, the rootfs and the scripts are in it, and both kernel copies in it (`boot-patcher/Image.gz-dtb` and the one in `kernel-nethunter.zip`) are byte-identical to `Image.gz-dtb`.

### The devices.yml entry

```yaml
- raphael:
    model  : Xiaomi Mi 9T Pro / Redmi K20 Pro
    kernels:
      - id          : raphael-vos-ksu
        description : Xiaomi Mi 9T Pro / Redmi K20 Pro for VoltageOS w/ KernelSU-Next
        kernelstring: NetHunter kernel for Xiaomi Mi 9T Pro (VoltageOS 6.2, KernelSU-Next)
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
            features   : [HID-4, BT_RFCOMM, ATH9K_HTC, RT2800USB, MAC80211_HWSIM, USB_ACM, FTDI, CH341, CP210X, BTUSB, Docker, KernelSU]
```

About the entry:

- `id`: the codename, then `vos` for VoltageOS, as the README of kali-nethunter-kernels asks for a ROM that is not stock. `-ksu` marks a kernel with KernelSU, like the official `alioth-los-ksu`.
- `android: seventeen`: the name for Android 17. The names are the Android version in words: `fourteen`, `fifteen`, `sixteen`. At this commit, `build.py` has flags only up to `--sixteen`. The script gives no Android flag. Then `build.py` checks all folders `kernels/<name>/raphael-vos-ksu`, finds only `seventeen`, and uses it (log: `Auto selecting kernel image: seventeen`). No patch to `build.py` is needed.
- `modules: 0`: AnyKernel3 does not copy modules into `/system`. It is the safe value: with `modules: 1`, a recovery install writes into the system partition. The KernelSU module install copies the modules in all cases (`push_modules` in `update-magisk`).
- `slot_device: 0` and `block`: raphael has one boot partition, without A/B slots. The AnyKernel3 script of this installer version finds the boot partition by itself and does not read these two values.
- `devicenames`: the values of `getprop ro.product.device`. The Full zip does not check them (`do.devicecheck=0`).
- `features`: text for the NetHunter web pages only. The list is the real content of this kernel.

## Install

### Order on a freshly flashed VoltageOS 6.2

1. Flash VoltageOS 6.2 and boot it once: [step 2](02-flash-rom-kernel-root.md), parts 1 to 4.
2. Flash `boot-docker.img`: [part 5](02-flash-rom-kernel-root.md#5-flash-the-custom-kernel). This is the only step that changes the kernel.
3. Install the KernelSU-Next manager v1.1.1 and check root: [part 6](02-flash-rom-kernel-root.md#6-root-kernelsu-next-manager).
4. Install the NetHunter Full zip as a KernelSU module ([below](#install-the-zip-needs-root)).

[SSH into Kali](04-ssh.md) needs the Kali chroot, so set it up after this step.

### Why the zip and boot-docker.img do not fight

- In a KernelSU module install, the NetHunter script does not flash a kernel. The function `do_flash` in `META-INF/com/google/android/update-magisk` stops when it runs under KernelSU and prints `Kernel flashing is skipped under KernelSU`. The kernel stays the one from `boot-docker.img`.
- The kernel in the zip is the same file as the kernel in `boot-docker.img`. The build stops if they are different.
- The modules in the zip are signed with the key of this kernel. Another kernel does not load them.

Rules:

- The installer then prints `Flash kernel-nethunter.zip via the manager's 'Flash AnyKernel Zip' instead`. **Do not do this.** `boot-docker.img` already has this kernel. AnyKernel3 would repack the boot image and try to add the NetHunter init files. Their USB part is for old kernels (`/sys/class/android_usb`), and this kernel does not have it.
- Do not flash the zip in recovery. The recovery path writes into `/system` and changes the boot image. It is not tested.
- After a new kernel build: flash the new `boot-docker.img` first, then build this zip again and install it again. A new kernel build can have a new signing key, and then the old modules do not load.

### Install the zip (needs root)

First check that the phone runs the kernel of this build. The modules in the zip load only with it:

```bash
$ADB shell cat /proc/version   # 4.14.357-Alchemy ... #2 SMP PREEMPT Sun Nov 15 04:35:37 CET 2026
```

If it shows another build, flash this `boot-docker.img` first. Then install the zip:

```bash
$ADB push nethunter-build/out/nethunter-2026.3-5-gaa1dca6-raphael-vos-ksu-seventeen-kalifs_full.zip /data/local/tmp/
$ADB shell su -c '/data/adb/ksud module install /data/local/tmp/nethunter-2026.3-5-gaa1dca6-raphael-vos-ksu-seventeen-kalifs_full.zip'
```

The screen must stay on. The install takes about 5 minutes. Most of the time is the rootfs: 1.8 GB of xz goes to `/data/local/nhsystem`. These lines in the output are important:

- `* NetHunter (KernelSU)`
- `- Modules copied successfully to /system/lib/modules.`
- `- Kernel flashing is skipped under KernelSU`
- `- Kali arm64 full chroot installed successfully!`

Then check the new module folder. It must not have a `kalifs-*.tar.xz` file. The `rm -f` line is only a safety step: this installer version does not copy the archive.

```bash
$ADB shell su -c 'ls /data/adb/modules_update/nethunter/'
$ADB shell su -c 'rm -f /data/adb/modules_update/nethunter/kalifs-*.tar.xz'
$ADB shell rm /data/local/tmp/nethunter-2026.3-5-gaa1dca6-raphael-vos-ksu-seventeen-kalifs_full.zip
$ADB reboot
```

After the reboot, open the NetHunter app and grant root. The Kali chroot is `/data/local/nhsystem/kali-arm64` (link: `kalifs`).

### Check after the reboot

```bash
$ADB shell uname -r                                                     # 4.14.357-Alchemy
$ADB shell su -c 'ls /data/adb/modules/nethunter/system/lib/modules/'   # 4.14.357-Alchemy
$ADB shell su -c 'ls /system/etc/firmware/ath9k_htc/'                   # htc_7010-1.4.0.fw  htc_9271-1.4.0.fw
```

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

To add a missing feature: add the option to [`kernel-build/nethunter.config`](../kernel-build/nethunter.config), build the kernel, flash the new `boot-docker.img`, then build and install this zip again.

## Verified on the PC

- The kernel in the zip (both copies) is byte-identical to the kernel in `boot-docker.img`: `4.14.357-Alchemy`.
- All 8 modules in the zip have `vermagic=4.14.357-Alchemy` and are signed with the key that is built into this kernel.
- The zip has no damaged data (`unzip -t`). The rootfs entry is stored, not compressed again. The zip is smaller than 2 GiB and has no ZIP64 records.
- The rootfs matches the published SHA-256. The apps match the SHA-512 values in `build.py`.
- The scripts in the zip: `customize.sh` has `SKIPUNZIP=1` and does not unpack `kalifs-*`. `update-magisk` skips the kernel flash under KernelSU. `push_modules` finds the folder `boot-patcher/modules/system_root/lib/modules/4.14.357-Alchemy`.

## Tested on the phone

On 2026-11-15, on VoltageOS 6.2 (Android 17):

- `ksud module install` of this zip ended with exit code 0. After the reboot, the module `nethunter` 1.4.0 is active.
- The installer printed `Kernel flashing is skipped under KernelSU`. The kernel stayed the one from `boot-docker.img`.
- No `kalifs-*.tar.xz` was left in the module folder (161 MB).
- The 5 apps are installed: NetHunter 2026.3, NetHunter Terminal 2025.4, KeX v5.2.5-1, Store 2019.3b and the Store privileged extension.
- The Kali chroot is Kali GNU/Linux Rolling (9.3 GB).
- `insmod` of the signed `mac80211_hwsim.ko` worked: a fake radio `phy1` appeared. `rmmod` worked too.

Not tested yet:

- `modprobe` in Kali, and firmware loading for USB Wi-Fi adapters through `ueventd`.
- HID, RNDIS and mass storage gadgets with the NetHunter app.
- The internal Wi-Fi and Bluetooth with the NetHunter firmware files in `/system/etc/firmware`. The files are for USB adapters. A name conflict with the phone firmware is not expected, but it is not checked.
- The recovery install and the `kernel-nethunter.zip` flash. Do not use them.

## Problems and removal

- If Android does not start after the install: press Volume Down 3 times while the phone boots. KernelSU then starts in safe mode with all modules off. Remove the module, then reboot.
- Remove NetHunter: first remove the chroot in the NetHunter app (Kali Chroot Manager). Then run `$ADB shell su -c '/data/adb/ksud module uninstall nethunter'`, reboot, and uninstall the apps (`$ADB uninstall com.offsec.nethunter`, and the same for `com.offsec.nhterm`, `com.offsec.nethunter.kex`, `com.offsec.nethunter.store`, `com.offsec.nethunter.store.privileged`).

## Notes

- Like the Lite zip, the installer sets the NetHunter wallpaper and boot animation.
- The NetHunter app sets SELinux to Permissive each time it starts. Check with `getenforce`. `su -c 'setenforce 1'` sets Enforcing again, and Kali still works.
- Never delete the chroot with `rm -rf` while it runs. `/sdcard` is mounted inside it, and the delete wipes the phone's storage.
