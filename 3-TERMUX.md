# 3. Termux + SSH

## Grant Root Access

Open **KernelSU-Next Manager** → **Superuser** → grant **Termux** root access.

## Install

Install from F-Droid:
- [Termux](https://f-droid.org/en/packages/com.termux/)
- [Termux:Boot](https://f-droid.org/packages/com.termux.boot/)

## Setup SSH

```bash
pkg install openssh
passwd
sshd
```

Connect from PC: `ssh <user>@<phone-ip> -p 8022`

## Add SSH Key

Copy your public key to the phone to connect without a password:

```bash
ssh-copy-id -i ~/.ssh/id_rsa -p 8022 <user>@<phone-ip>
```

## Auto-start sshd on boot

```bash
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-sshd << 'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
EOF
chmod +x ~/.termux/boot/start-sshd
```

Open Termux:Boot app once (registers it for boot events).

## Prevent Android from killing Termux

Disable battery optimization for both Termux and Termux:Boot:

Settings → Apps → select app → Battery → **Unrestricted**

See [dontkillmyapp.com](https://dontkillmyapp.com/) for device-specific tips.
