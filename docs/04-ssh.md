# 4. SSH into Kali

`ssh kali` opens a root shell in the Kali chroot. Kali's own `sshd` answers it. KernelSU starts that `sshd` at every boot, as root.

Why not Termux: an `sshd` in Termux runs as the user of the Termux app, and Android kills it together with the Termux app. A root process from a KernelSU boot script belongs to no app, so Android does not kill it that way.

Do this after [NetHunter](03-nethunter.md): it needs the Kali chroot at `/data/local/nhsystem/kalifs`.

## Phone address

The phone uses a random Wi-Fi MAC address for each network. A wipe or a change of the network settings makes a new one, and the router then gives a new IP address. So set a static address on the phone:

Settings → Network & internet → Internet → gear of the Wi-Fi → Edit → Advanced options:

- IP settings: **Static**
- IP address: a free address in your network, here `192.168.1.229`. Gateway and DNS: your router, here `192.168.1.1`. Prefix length `24`.
- Press **Save**. Without Save, Android forgets the change.

## Install

Run this from the repo root on the PC. `$ADB` is the adb command from [step 2](02-flash-rom-kernel-root.md#requirements).

```bash
awk '{print $1" "$2}' ~/.ssh/id_mi9tpro.pub > authorized_keys
$ADB push authorized_keys config/kali/10-phone.conf config/android/kali-sshd.sh /data/local/tmp/
rm authorized_keys
$ADB shell su -c '
K=/data/local/nhsystem/kalifs
mkdir -p $K/root/.ssh && chmod 700 $K/root/.ssh
cp /data/local/tmp/authorized_keys $K/root/.ssh/authorized_keys && chmod 600 $K/root/.ssh/authorized_keys
cp /data/local/tmp/10-phone.conf $K/etc/ssh/sshd_config.d/10-phone.conf && chmod 644 $K/etc/ssh/sshd_config.d/10-phone.conf
cp /data/local/tmp/kali-sshd.sh /data/adb/service.d/kali-sshd.sh && chmod 755 /data/adb/service.d/kali-sshd.sh
rm -f /data/local/tmp/authorized_keys /data/local/tmp/10-phone.conf /data/local/tmp/kali-sshd.sh
sh /data/adb/service.d/kali-sshd.sh'
```

- [config/android/kali-sshd.sh](../config/android/kali-sshd.sh) is the boot script. It waits for the end of the boot and takes a wake lock, so SSH answers when the screen is off (this uses more battery). It creates the host keys once, then starts Kali's `sshd` in a private mount namespace.
- [config/kali/10-phone.conf](../config/kali/10-phone.conf) allows keys only. Kali can ship a user `kali` with the password `kali`.

## PC side

1. Add [config/pc/ssh-config](../config/pc/ssh-config) to `~/.ssh/config`.
2. Check the new host key before you trust it. Read it over USB, then compare it with the key that comes over Wi-Fi:
   ```bash
   $ADB shell su -c 'cat /data/local/nhsystem/kalifs/etc/ssh/ssh_host_ed25519_key.pub'
   ssh-keyscan -t ed25519 192.168.1.229 | grep -v '^#'
   ```
   If both keys are the same, remove the old key with `ssh-keygen -R 192.168.1.229`, then add the line `192.168.1.229 <key>` to `~/.ssh/known_hosts`.
3. Test: `ssh kali`.

## Termux (optional)

SSH does not need Termux. To reach Termux too (`ssh termux`, port 8022):

1. Install Termux and Termux:Boot from `apks/`. Open both once.
2. In Termux: `pkg update`, `pkg install openssh`, put the key into `~/.ssh/authorized_keys`, run `sshd`.
3. [config/termux/start-sshd](../config/termux/start-sshd) in `~/.termux/boot/` starts `sshd` at boot. On 2026-11-15, Termux:Boot did not start it after a reboot. The cause is not known.
4. Exempt Termux from Android's battery limits and from the phantom process killer:
   ```bash
   $ADB shell dumpsys deviceidle whitelist +com.termux
   $ADB shell dumpsys deviceidle whitelist +com.termux.boot
   $ADB shell settings put global settings_enable_monitor_phantom_procs false
   $ADB shell device_config set_sync_disabled_for_tests persistent
   $ADB shell device_config put activity_manager max_phantom_processes 2147483647
   ```
