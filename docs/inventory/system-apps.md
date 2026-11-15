# System apps

Changes to system apps on the old setup. Check each one after the new install: some may already be the ROM default.

| Package | App | State | Command (from the PC) |
|---------|-----|-------|-----------------------|
| `com.android.devicelockcontroller` | Device Lock controller | disabled | `adb shell pm disable-user --user 0 com.android.devicelockcontroller` |
| `com.android.privatespace` | Private space | removed for user 0 | `adb shell pm uninstall --user 0 com.android.privatespace` |
| `org.akanework.gramophone` | Gramophone (music) | removed for user 0 | `adb shell pm uninstall --user 0 org.akanework.gramophone` |
| `org.lineageos.aperture` | Aperture (camera) | removed for user 0 | `adb shell pm uninstall --user 0 org.lineageos.aperture` |

To undo a removal: `adb shell cmd package install-existing <package>`.
