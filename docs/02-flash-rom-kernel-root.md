# 2. Flash ROM, kernel and root

> **WARNING:** part 3 erases everything on the phone.

## Requirements

- An unlocked bootloader.
- [ADB and fastboot](https://developer.android.com/tools/releases/platform-tools) on the PC, and the USB drivers for them.
- The VoltageOS zip for raphael from [voltage-os.com](https://voltage-os.com/), for example `voltage-6.2-raphael-20261022-0545-OFFICIAL.zip`.
- `boot-docker.img` from [step 1](01-build-kernel.md).
- The Magisk APK: [`download-apks.sh`](../download-apks.sh) downloads it ([step 6](06-apps.md#download-the-apks)).

The guides use `$ADB` and `$FB`. On Linux:

```bash
ADB=adb
FB=fastboot
```

WSL has no USB. On WSL, use the Windows tools:

```bash
ADB=/mnt/c/<path to platform-tools>/adb.exe
FB=/mnt/c/<path to platform-tools>/fastboot.exe
```

If a Windows tool cannot read a file in WSL, copy the file to a Windows folder and give its Windows path, for example `'C:\Users\<you>\Downloads\boot-docker.img'`.

## 1. Take the images from the ROM zip

The VoltageOS zip has `boot.img` and `recovery.img` directly (no `payload.bin`):

```bash
unzip -j voltage-*-raphael-*-OFFICIAL.zip boot.img recovery.img dtbo.img vbmeta.img -d kernel-build/stock-6.2
```

Keep `boot.img`: it is the stock kernel. The ROM installer writes this file to the boot partition without changes (`package_extract_file("boot.img", ...)` in `updater-script`), so it is an exact backup. `kernel-build/stock-*/` is ignored by git.

## 2. Flash the recovery of the new ROM

A new ROM version can need its own recovery.

```bash
$ADB reboot bootloader
$FB getvar product            # must print: raphael
$FB flash recovery kernel-build/stock-6.2/recovery.img
$FB reboot recovery           # or: Volume Up + Power
```

Go into the recovery directly after the flash.

On VoltageOS 6.2 with this kernel, `adb reboot recovery` and `fastboot reboot recovery` can end in fastboot or in Android, although the recovery partition is correct. Then boot the recovery once from the PC: `$FB boot kernel-build/stock-6.2/recovery.img`.

## 3. Format data and install VoltageOS

In the recovery:

1. **Factory reset** → **Format data / factory reset**. This erases everything on the phone.
2. **Apply update** → **Apply from ADB**.

On the PC:

```bash
$ADB sideload voltage-<version>-raphael-<date>-OFFICIAL.zip
```

The progress often stops at about 47% or 94%. This is normal. Wait until the recovery reports the end, then choose **Reboot system now**.

## 4. First boot and USB debugging

The first boot takes 5 to 10 minutes. Then:

1. Go through the setup screens.
2. Settings → About phone → tap **Build number** 7 times.
3. Settings → System → Developer options → switch on **USB debugging**. Allow the PC when the phone asks.

This first boot uses the stock kernel. If the ROM has a problem, you see it now, before the custom kernel.

## 5. Flash the custom kernel with Magisk root

The kernel has no root code. Magisk gives root: it patches `boot-docker.img`, and you flash the patched image. [`download-apks.sh`](../download-apks.sh) downloads Magisk (see [step 6](06-apps.md#download-the-apks)).

1. Install Magisk and copy the kernel image to the phone:
   ```bash
   $ADB install apks/Magisk-v31.1.apk
   $ADB push boot-docker.img /sdcard/Download/boot-docker.img
   ```
2. On the phone: **Magisk** → **Install** (on the Magisk card) → **Select and Patch a File** → `Download/boot-docker.img` → **Let's go**. Wait for **All done!**. Magisk writes `Download/magisk_patched-<version>_<random>.img`.
3. Flash the patched image:
   ```bash
   $ADB shell ls /sdcard/Download/                          # find the name magisk_patched-*.img
   $ADB pull /sdcard/Download/magisk_patched-31100_<random>.img boot-magisk.img
   $ADB reboot bootloader
   $FB getvar product                                       # must print: raphael
   $FB flash boot boot-magisk.img
   $FB reboot
   ```
4. After the boot, check the kernel and Magisk. The build date is the date of your build:
   ```bash
   $ADB shell cat /proc/version   # 4.14.357-Alchemy ... Clang version 22.0.2 ... #1 SMP PREEMPT <build date>
   $ADB shell magisk -v           # 31.1:MAGISK:R
   ```

Do this again after each new kernel build: patch the new `boot-docker.img` with Magisk, then flash it.

If the phone does not boot, hold **Volume Down + Power** until fastboot shows, then flash the stock kernel back. The phone then works without root:

```bash
$FB flash boot kernel-build/stock-6.2/boot.img
$FB reboot
```

## 6. Root for adb

1. Run `$ADB shell su -c id`. Magisk asks on the phone: tap **Grant**. The question closes after about 10 seconds and then says no. In that case: **Magisk** → **Superuser** → switch on **Shell**.
2. Check: `$ADB shell su -c id` prints `uid=0(root)`.

The next steps grant root to more apps: NetHunter, NetHunter Terminal and AccA (see the [inventory](inventory/apps.md)).
