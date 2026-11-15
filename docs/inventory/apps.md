# Apps

User apps on the old setup (VoltageOS 5.6, 2026-11-15).

| App | Package | Version | Source | Root |
|-----|---------|---------|--------|------|
| KernelSU-Next manager | `com.rifsxd.ksunext` | v1.1.1 | [GitHub release](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.1.1) | — |
| Termux | `com.termux` | 0.118.3 | [F-Droid](https://f-droid.org/packages/com.termux/) | yes |
| Termux:Boot | `com.termux.boot` | 0.8.1 | [F-Droid](https://f-droid.org/packages/com.termux.boot/) | no |
| NetHunter | `com.offsec.nethunter` | 2026.3 | NetHunter zip (see [step 3](../03-nethunter.md)) | yes |
| NetHunter Terminal | `com.offsec.nhterm` | 2025.4 | NetHunter zip | yes |
| NetHunter KeX | `com.offsec.nethunter.kex` | v5.2.5-1 | NetHunter zip | no |
| NetHunter Store | `com.offsec.nethunter.store` | 2019.3b | NetHunter zip | no |
| NetHunter Store privileged extension | `com.offsec.nethunter.store.privileged` | 0.2.13-nethunter | NetHunter zip | no |
| AccA | `mattecarra.accapp` | 1.0.35 | [F-Droid](https://f-droid.org/packages/mattecarra.accapp/) | yes |
| Hail | `com.aistra.hail` | 1.10.0 | [F-Droid](https://f-droid.org/packages/com.aistra.hail/) | yes |
| Total Commander | `com.ghisler.android.TotalCommander` | 3.62d | APK from [ghisler.com](https://www.ghisler.com/android.htm) | no |
| F-Droid | `org.fdroid.fdroid` | 1.23.2 | [f-droid.org](https://f-droid.org/) | no |

Version = the version on the old setup. [`download-apks.sh`](../../download-apks.sh) gets the current F-Droid version, so some apps can be newer.

Termux and Termux:Boot must come from the same source. Both come from F-Droid here. Android refuses plugins with a different signature.

## Root (KernelSU allow list)

Grant root in the KernelSU-Next manager to: Termux, NetHunter, NetHunter Terminal, AccA, Hail, and Shell (`com.android.shell`, for `adb shell su`).

## KernelSU modules

| Module | Version |
|--------|---------|
| `nethunter` (Kali NetHunter) | 1.4.0 |

ACC is not a module here. AccA installs it into `/data/adb/vr25`.
