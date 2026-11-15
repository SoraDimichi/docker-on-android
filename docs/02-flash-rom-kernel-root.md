# 2. Flash ROM, kernel and root

> **WARNING:** part 3 erases everything on the phone.

## Requirements

- An unlocked bootloader.
- [ADB and fastboot](https://developer.android.com/tools/releases/platform-tools) on the PC, and the USB drivers for them.
- The VoltageOS zip for raphael from [voltage-os.com](https://voltage-os.com/), for example `voltage-6.2-raphael-20261022-0545-OFFICIAL.zip`.
- `boot-docker.img` from [step 1](01-build-kernel.md).

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

## 5. Flash the custom kernel

```bash
$ADB reboot bootloader
$FB getvar product            # must print: raphael
$FB flash boot boot-docker.img
$FB reboot
```

After the boot, check the kernel. The build date is the date of your build:

```bash
$ADB shell cat /proc/version   # 4.14.357-Alchemy ... #2 SMP PREEMPT <build date>
```

If the phone does not boot, hold **Volume Down + Power** until fastboot shows, then flash the stock kernel back. The phone then works without root:

```bash
$FB flash boot kernel-build/stock-6.2/boot.img
$FB reboot
```

## 6. Root: KernelSU-Next manager

The manager version must match the kernel: v1.1.1. [`download-apks.sh`](../download-apks.sh) downloads it (see [step 6](06-apps.md#download-the-apks)).

```bash
$ADB install apks/KernelSU_Next_v1.1.1_12851-release.apk
```

1. Open **KernelSU Next**. It must show **Working**.
2. **Superuser** tab → switch on **Shell** (`com.android.shell`). If Shell is not in the list, show the system apps in the menu (⋮). adb then gets root.
3. Check: `$ADB shell su -c id` prints `uid=0(root)`.

The next steps grant root to more apps: NetHunter, NetHunter Terminal, AccA and Hail (see the [inventory](inventory/apps.md)).
