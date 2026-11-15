# 4. SSH into Kali

`ssh kali` opens a root shell in the Kali chroot. Kali's own `sshd` answers it. The NetHunter app starts it after each boot (Kali Services). A Magisk boot script keeps the CPU awake, so SSH answers also when the screen is off.

Do this after [NetHunter](03-nethunter.md). The NetHunter app starts its services after the first screen unlock after a boot, so SSH answers from then on.

## Phone address

The phone uses a random Wi-Fi MAC address for each network. A wipe or a change of the network settings makes a new one, and the router then gives a new IP address. So set a static address on the phone:

Settings → Network & internet → Internet → gear of the Wi-Fi → Edit → Advanced options:

- IP settings: **Static**
- IP address: a free address in your network, here `192.168.1.229`. Gateway and DNS: your router, here `192.168.1.1`. Prefix length `24`.
- Press **Save**. Without Save, Android forgets the change.

## Kali side

Open the NetHunter app once before: it mounts the Kali chroot. Then run this from the repo root on the PC. `$ADB` is the adb command from [step 2](02-flash-rom-kernel-root.md#requirements).

```bash
awk '{print $1" "$2}' ~/.ssh/id_mi9tpro.pub > authorized_keys
$ADB push authorized_keys config/kali/10-phone.conf /data/local/tmp/
rm authorized_keys
$ADB shell su -c sh <<'EOF'
K=/data/local/nhsystem/kalifs
mkdir -p $K/root/.ssh && chmod 700 $K/root/.ssh
cp /data/local/tmp/authorized_keys $K/root/.ssh/authorized_keys && chmod 600 $K/root/.ssh/authorized_keys
cp /data/local/tmp/10-phone.conf $K/etc/ssh/sshd_config.d/10-phone.conf && chmod 644 $K/etc/ssh/sshd_config.d/10-phone.conf
rm -f /data/local/tmp/authorized_keys /data/local/tmp/10-phone.conf
[ -f $K/etc/ssh/ssh_host_ed25519_key ] || chroot $K /usr/bin/ssh-keygen -A
EOF
```

- [config/kali/10-phone.conf](../config/kali/10-phone.conf) allows keys only. Kali can ship a user `kali` with the password `kali`.
- A new Kali has no SSH host keys, and `sshd` does not start without them. `ssh-keygen -A` makes them once. It needs `/dev/null` in the chroot, which the NetHunter app mounts.

## Start SSH, also at boot

In the NetHunter app: **Kali Services** → **SSH**:

1. Switch it on. This runs `service ssh start` in Kali.
2. Tick the checkbox of SSH, for the start with the chroot. After each boot, NetHunter runs the command again (script `80postservices` of the app).

In NetHunter 2026.3, this screen can crash the app (`ConcurrentModificationException` in `KaliServicesExecutor`). The service starts anyway. Check it:

```bash
$ADB shell su -c 'ps -A | grep sshd'   # sshd [listener] ...
```

If the app crashes before it saves the checkbox, put the command into the list that NetHunter runs after each boot. The app writes this list again from its own database when you change the services, so tick the box in the app later when it works.

```bash
$ADB shell su -c "printf 'service ssh start\n' > /data/data/com.offsec.nethunter/scripts/kaliservices && chmod 755 /data/data/com.offsec.nethunter/scripts/kaliservices"
```

## Wake lock

When the screen is off, Android puts the phone into deep sleep after some time. Then `sshd` and Docker containers do not answer until the phone wakes up. [config/android/wakelock.sh](../config/android/wakelock.sh) holds a wake lock from each boot: the CPU stays awake, the screen still turns off. This uses more battery. Magisk runs the scripts in `/data/adb/service.d` at boot:

```bash
$ADB push config/android/wakelock.sh /data/local/tmp/
$ADB shell su -c 'mkdir -p /data/adb/service.d && cp /data/local/tmp/wakelock.sh /data/adb/service.d/wakelock.sh && chmod 755 /data/adb/service.d/wakelock.sh && rm /data/local/tmp/wakelock.sh && sh /data/adb/service.d/wakelock.sh'
$ADB shell cat /sys/power/wake_lock   # kali-ssh
```

## PC side

1. Add [config/pc/ssh-config](../config/pc/ssh-config) to `~/.ssh/config`.
2. Check the new host key before you trust it. Read it over USB, then compare it with the key that comes over Wi-Fi:
   ```bash
   $ADB shell su -c 'cat /data/local/nhsystem/kalifs/etc/ssh/ssh_host_ed25519_key.pub'
   ssh-keyscan -t ed25519 192.168.1.229 | grep -v '^#'
   ```
   If both keys are the same, remove the old key with `ssh-keygen -R 192.168.1.229`, then add the line `192.168.1.229 <key>` to `~/.ssh/known_hosts`.
3. Test: `ssh kali`.

## Android shell from Kali

Android's own root file system is `/proc/1/root`. From a root shell in Kali, this opens a root shell in Android, for example for `getprop`, `cmd package` or `settings`:

```bash
chroot /proc/1/root /system/bin/env -i PATH=/product/bin:/apex/com.android.runtime/bin:/system_ext/bin:/system/bin:/system/xbin:/odm/bin:/vendor/bin HOME=/ /system/bin/sh
```
