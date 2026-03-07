# Debloating EvolutionX (GApps)

Disable Google bloat to free ~1 GB RAM for Docker containers.

> Tested on EvolutionX 16.0 (`raphael`). All commands are reversible.

## Prerequisites

Install FOSS replacements **before** disabling Google apps:

| Replace | With | Install from |
|---------|------|-------------|
| Gboard | [HeliBoard](https://github.com/Helium314/HeliBoard) | F-Droid |
| Pixel Launcher | [KISS Launcher](https://kisslauncher.com/) | F-Droid |
| Chrome | [Fennec](https://f-droid.org/packages/org.mozilla.fennec_fdroid/) | F-Droid |
| Google Messages | [QKSMS](https://f-droid.org/packages/com.moez.QKSMS/) or Signal | F-Droid |
| Google Photos | [Simple Gallery](https://f-droid.org/packages/com.simplemobiletools.gallery.pro/) | F-Droid |
| Google Calendar | [Simple Calendar](https://f-droid.org/packages/com.simplemobiletools.calendar.pro/) | F-Droid |
| Google Contacts | [Simple Contacts](https://f-droid.org/packages/com.simplemobiletools.contacts.pro/) | F-Droid |
| Google Files | [Simple File Manager](https://f-droid.org/packages/com.simplemobiletools.filemanager.pro/) | F-Droid |
| Google Dialer | [Simple Dialer](https://f-droid.org/packages/com.simplemobiletools.dialer/) | F-Droid |
| Play Store | [F-Droid](https://f-droid.org/) | Already installed |

After installing, set defaults:
1. **Keyboard**: Settings → System → Languages & input → set HeliBoard as default
2. **Launcher**: Press Home → select KISS → set "Always"

## Debloat

All commands use `pm uninstall -k --user 0` — removes for current user but keeps system data. Reversible. Run from Termux or SSH:

```bash
su
```

### Google Apps (safe, ~600 MB saved)

```bash
for pkg in \
  com.google.android.googlequicksearchbox \
  com.google.android.apps.messaging \
  com.google.android.apps.photos \
  com.google.android.calendar \
  com.google.android.contacts \
  com.google.android.calculator \
  com.google.android.deskclock \
  com.google.android.dialer \
  com.google.android.apps.recorder \
  com.google.android.apps.nbu.files \
  com.google.android.apps.weather \
  com.google.android.apps.wellbeing \
  com.google.android.apps.bard \
  com.google.android.apps.turbo \
  com.google.android.markup \
  com.google.android.apps.safetyhub \
  com.google.android.soundpicker \
  com.google.android.projection.gearhead \
  com.google.android.tts \
  com.google.android.storagemanager \
  com.android.chrome \
; do
  pm uninstall -k --user 0 $pkg
done
```

### Keyboard + Launcher (~400 MB saved)

Only run after setting FOSS replacements as default:

```bash
for pkg in \
  com.google.android.inputmethod.latin \
  com.google.android.apps.nexuslauncher \
; do
  pm uninstall -k --user 0 $pkg
done
```

### Play Store + Google Services (~700 MB saved)

```bash
for pkg in \
  com.android.vending \
  com.google.android.gms \
; do
  pm uninstall -k --user 0 $pkg
done
```

### Accessibility + AI + Wallpapers + Misc

```bash
for pkg in \
  com.google.android.marvin.talkback \
  com.google.android.apps.accessibility.voiceaccess \
  com.google.android.accessibility.soundamplifier \
  com.google.android.accessibility.switchaccess \
  com.google.audio.hearing.visualization.accessibility.scribe \
  com.google.android.apps.aiwallpapers \
  com.google.android.apps.emojiwallpaper \
  com.google.android.apps.wallpaper \
  com.google.android.apps.wallpaper.pixel \
  com.google.android.wallpaper.effects \
  com.google.pixel.livewallpaper \
  com.google.ar.core \
  com.google.android.apps.wearables.maestro.companion \
  com.google.android.apps.pixel.nowplaying \
  com.google.android.apps.restore \
  com.google.android.feedback \
  com.google.android.apps.work.clouddpc \
  com.google.android.apps.privacy.wildlife \
  com.google.android.apps.magicportrait \
  com.google.ambient.streaming \
  com.google.android.flipendo \
  com.google.android.mosey \
  com.google.android.odad \
  com.google.android.as \
  com.google.android.as.oss \
  com.google.android.pcs \
  com.google.android.configupdater \
  com.google.android.onetimeinitializer \
  com.google.android.partnersetup \
  com.google.android.apps.customization.pixel \
  com.google.android.apps.pixel.customizationbundle \
  com.google.android.avatarpicker \
  com.google.android.pixel.avatarpicker_gms \
  com.google.android.apps.pixel.relationships \
  com.google.android.apps.pixel.subzero \
  com.google.android.carrierlocation \
  com.google.android.apps.carrier.log \
  com.google.android.apps.cbrsnetworkmonitor \
  com.google.android.googlequicksearchbox.nga_resources \
  com.android.hotwordenrollment.okgoogle \
  com.android.hotwordenrollment.xgoogle \
  com.google.android.printservice.recommendation \
  com.google.android.tag \
  com.google.mainline.telemetry \
  com.google.mainline.adservices \
  com.android.adservices.api \
  com.android.federatedcompute.services \
  com.android.ondevicepersonalization.services \
; do
  pm uninstall -k --user 0 $pkg
done
```

## Results

| | Before | After |
|---|--------|-------|
| Available RAM | 2,120 MB | 3,167 MB |
| Saved | | **~1 GB** |

## Undo

Restore a single package:

```bash
su -c "pm install-existing --user 0 com.google.android.gms"
```

Restore everything:

```bash
# List uninstalled packages and reinstall
pm list packages -u | sed 's/package://' | while read pkg; do
  pm list packages | grep -q "$pkg" || pm install-existing --user 0 "$pkg"
done
```

## Do NOT disable

These will bootloop or break the system:

- `com.android.systemui` — screen goes black
- `com.android.settings` / `com.google.android.settings.intelligence`
- `com.android.phone` / `org.codeaurora.ims` — telephony
- `com.google.android.webview` — apps crash
- `com.google.android.permissioncontroller`
- `com.android.providers.*` — system databases
- `com.google.android.setupwizard` / `com.google.android.pixel.setupwizard`
- `com.google.android.gsf` — Google Services Framework
- `com.google.android.ext.services`
