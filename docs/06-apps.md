# 6. Apps: APKs and ACC

## Download the APKs

Run [`download-apks.sh`](../download-apks.sh) from the repo root. It saves the APKs in [`apks/`](../apks) and checks each file against the SHA-256 that F-Droid or GitHub publishes. Git keeps only the empty `apks/` folder.

- From F-Droid: AccA, F-Droid.
- From GitHub: Magisk v31.1. [Step 2](02-flash-rom-kernel-root.md) needs it for root.
- Total Commander is not on F-Droid. Get it from [ghisler.com](https://www.ghisler.com/android.htm).
- The NetHunter apps come with the NetHunter zip ([step 3](03-nethunter.md)).

Install an APK:

```bash
$ADB install apks/<file>.apk
```

## ACC and AccA (charge limit)

1. Install AccA and grant it root in Magisk.
2. Open AccA once. It installs ACC to `/data/adb/vr25`. ACC is not a Magisk module.
3. Set the charge limit. [`config/acc/config.txt`](../config/acc/config.txt) has the values. The main line is `capacity=(5 60 70 80 false)`: charging stops at 80% and starts again at 70%.

Set the same values in AccA, or copy the file:

```bash
$ADB push config/acc/config.txt /data/local/tmp/acc-config.txt
$ADB shell su -c 'cp /data/local/tmp/acc-config.txt /data/adb/vr25/acc-data/config.txt'
```

Then restart ACC in AccA, or reboot.

"Not charging" between 70% and 80% is normal: ACC holds the charge in that range.

## System apps

The old setup disabled or removed some system apps. The list and the commands are in [inventory/system-apps.md](inventory/system-apps.md).
