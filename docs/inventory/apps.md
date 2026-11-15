# Apps

Apps of this setup (VoltageOS 6.2, 2026-11-15).

| App | Package | Version | Source | Root |
|-----|---------|---------|--------|------|
| Magisk | `com.topjohnwu.magisk` | 31.1 | [GitHub release](https://github.com/topjohnwu/Magisk/releases/tag/v31.1) | — |
| NetHunter | `com.offsec.nethunter` | 2026.3 | NetHunter zip (see [step 3](../03-nethunter.md)) | yes |
| NetHunter Terminal | `com.offsec.nhterm` | 2025.4 | NetHunter zip | yes |
| NetHunter KeX | `com.offsec.nethunter.kex` | v5.2.5-1 | NetHunter zip | no |
| NetHunter Store | `com.offsec.nethunter.store` | 2019.3b | NetHunter zip | no |
| NetHunter Store privileged extension | `com.offsec.nethunter.store.privileged` | 0.2.13-nethunter | NetHunter zip | no |
| AccA | `mattecarra.accapp` | 1.0.35 | [F-Droid](https://f-droid.org/packages/mattecarra.accapp/) | yes |
| F-Droid | `org.fdroid.fdroid` | 2.0.3 | [f-droid.org](https://f-droid.org/) | no |
| Total Commander (optional) | `com.ghisler.android.TotalCommander` | 3.62d | APK from [ghisler.com](https://www.ghisler.com/android.htm) | no |

[`download-apks.sh`](../../download-apks.sh) gets the current F-Droid version, so some apps can be newer.

## Root (Magisk Superuser)

Grant root in Magisk to: Shell (`com.android.shell`, for `adb shell su`), NetHunter, NetHunter Terminal and AccA. Magisk asks the first time an app wants root. The question closes after about 10 seconds. If you miss it, switch the app on in **Magisk** → **Superuser**.

## Magisk modules

| Module | Version |
|--------|---------|
| `nethunter` (Kali NetHunter) | 1.4.0 |

ACC is not a module here. AccA installs it into `/data/adb/vr25`.

## Boot scripts (`/data/adb/service.d`)

Magisk runs these scripts at each boot.

| Script | From |
|--------|------|
| `wakelock.sh` | [config/android/wakelock.sh](../../config/android/wakelock.sh), see [step 4](../04-ssh.md#wake-lock) |
| `acc-cleanup.sh` | AccA |
