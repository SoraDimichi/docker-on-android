# 1. Build Kernel

VoltageOS stock kernel is missing `CONFIG_CGROUP_DEVICE` and `CONFIG_CGROUP_PIDS` — Docker refuses to start without them.

The build also adds NetHunter kernel options. See [NetHunter features](#nethunter-features).

## Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
  bc bison flex libssl-dev libelf-dev make python3 git curl
```

## Build

```bash
cd kernel-build
bash build.sh
```

Output: `boot-docker.img` and `modules/<kernel version>/` (kernel modules) in the repo root. Next step: [Flash ROM + Kernel](02-flash-rom-kernel-root.md).

The script downloads [Android Clang r596125](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/tags/android-security-17.0.0_r3/clang-r596125) (Clang 22.0.2, ~1 GB), clones the [VoltageOS kernel](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael), applies the Docker and NetHunter config fragments, builds the kernel, the device tree and the modules, and packs the boot image. Takes ~30 min and ~10 GB disk. Read [`build.sh`](../kernel-build/build.sh) for details.

The kernel source stays clean: no patches and no root code. The build stops if `kernel/` has local changes. Root comes from Magisk, which patches `boot-docker.img` ([step 2](02-flash-rom-kernel-root.md#5-flash-the-custom-kernel-with-magisk-root)).

The device tree is built with `dtc -H epapr`: only `phandle` properties, like the VoltageOS build. By default, the `dtc` 1.4.4 in the kernel source also writes `linux,phandle`. The bootloader changes the `phandle` numbers when it applies the phone's `dtbo`, but the kernel reads the old `linux,phandle` numbers. Then the NFC driver and a camera fail with `invalid phandle`. With `-H epapr`, the device tree is byte-identical to the one in the VoltageOS `boot.img`. The build stops if `linux,phandle` comes back.

The compiler is the one of the VoltageOS kernel itself: the stock kernel's `/proc/version` shows `Clang version 22.0.2` (r596125). The AOSP `main` branch has only up to r547379. When `CLANG_VERSION` in `build.sh` changes, the script deletes `kernel/out` and keeps only the module signing key (`out/certs/signing_key.pem`, `signing_key.x509`, `x509.genkey`). Modules of earlier builds, for example in the NetHunter zip, then still load.

## NetHunter features

[`nethunter.config`](../kernel-build/nethunter.config) adds these kernel options for [Kali NetHunter](https://www.kali.org/docs/nethunter/):

| Options | Use |
|---------|-----|
| `MAC80211`, `ATH9K_HTC` (module), `RT2800USB` | USB Wi-Fi adapters with Atheros AR9271 or Ralink RT2800 chips |
| `MAC80211_HWSIM` (module) | Fake Wi-Fi radios to practice Wi-Fi attacks without hardware |
| `USB_ACM`, `USB_SERIAL`, `FTDI_SIO`, `CH341`, `CP210X` | USB serial devices: Arduino, ESP32 boards, M5Stack Cardputer, Flipper Zero, UART adapters |
| `BT_RFCOMM`, `BT_RFCOMM_TTY`, `BT_HCIBTUSB` | Bluetooth serial links and USB Bluetooth dongles |

The USB gadget functions for HID, RNDIS and mass storage attacks are already in the VoltageOS defconfig.

The phone's built-in Wi-Fi and Bluetooth do not change. USB Wi-Fi adapters also need their firmware files on the phone. The build does not include them.

`ATH9K_HTC` is a module because its `htc_start`, `htc_stop` and `htc_connect_service` have the same names as functions in the built-in Qualcomm Wi-Fi driver. Built in, the kernel does not link.

To use the modules, copy the folder `modules/<kernel version>/` to `/lib/modules/` in the Linux chroot on the phone. Then load a module as root:

```bash
modprobe mac80211_hwsim radios=2   # two fake Wi-Fi radios
modprobe ath9k_htc                 # Atheros AR9271 USB adapter
```

The kernel accepts only modules signed by the same build. Copy the modules again after each new build.

## Update to a new VoltageOS release

1. Extract `boot.img` from the VoltageOS zip and unpack it:
   ```bash
   unzip -j voltage-X.Y-raphael-*.zip boot.img -d kernel-build/stock-X.Y
   python3 kernel-build/mkbootimg/unpack_bootimg.py --boot_img kernel-build/stock-X.Y/boot.img --out kernel-build/stock-X.Y/unpacked --format=mkbootimg
   ```
2. Copy `unpacked/ramdisk` to `kernel-build/boot_unpacked/` and write the values from the unpack output to `boot_params.txt`. Keep the file name in `build.sh` (`--ramdisk`) in sync with the compression of the ramdisk.
3. In `build.sh`, set `KERNEL_BRANCH` and `KERNEL_COMMIT` to the kernel branch of the release. Set `OS_VERSION` and `OS_PATCH_LEVEL` to the values of the stock `boot.img`.
4. Move or remove `kernel-build/kernel`, then run `bash build.sh`.

## Sources

| Component | Source | License |
|-----------|--------|---------|
| Linux kernel (msm-4.14) | [VoltageOS-Devices/kernel_xiaomi_raphael](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael) branch `17` @ [`794b2ef`](https://github.com/VoltageOS-Devices/kernel_xiaomi_raphael/commit/794b2ef62510f29174be9cd0d682ef5e305e2b81) | [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) |
| Android Clang r596125 (22.0.2) | [AOSP prebuilts](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/tags/android-security-17.0.0_r3/clang-r596125), tag `android-security-17.0.0_r3` | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |
| mkbootimg | [AOSP system/tools/mkbootimg](https://android.googlesource.com/platform/system/tools/mkbootimg) | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |
| VoltageOS ramdisk | Extracted from [VoltageOS](https://voltage-os.com/) 6.2 boot.img | [Apache 2.0](https://source.android.com/docs/setup/about/licenses) |

Inspired by the [Antigravity kernel](https://github.com/xiziphus/kernel_xiaomi_raphael_antigravity) which ships Docker cgroup flags out of the box.