# 5. Docker

Docker runs inside the Kali chroot of [Kali NetHunter](https://www.kali.org/docs/nethunter/). NetHunter installs a full Kali at `/data/local/nhsystem/kalifs`. Kali is based on Debian, so `apt install docker.io` works there. No second Linux system is needed.

## Requirements

- The custom kernel from [step 1](01-build-kernel.md), with Magisk root ([step 2](02-flash-rom-kernel-root.md)).
- Kali NetHunter with its Kali chroot ([step 3](03-nethunter.md)). The Lite edition works too.
- `$ADB` on the PC ([step 2](02-flash-rom-kernel-root.md#requirements)), or another root shell on the phone.

## Copy the scripts to the phone

From the repo root:

```bash
$ADB push docker/setup.sh docker/start-docker.sh docker/stop-docker.sh docker/pause-docker.sh docker/resume-docker.sh docker/uninstall.sh /data/local/tmp/
$ADB shell su -c 'mkdir -p /data/local/docker-on-android && cd /data/local/tmp && mv setup.sh start-docker.sh stop-docker.sh pause-docker.sh resume-docker.sh uninstall.sh /data/local/docker-on-android/'
```

## Quick start

```bash
$ADB shell su -c 'sh /data/local/docker-on-android/setup.sh'          # once: installs docker.io and docker-cli in Kali
$ADB shell su -c 'sh /data/local/docker-on-android/start-docker.sh'   # after every reboot
```

`dockerd` does not start at boot. From a root shell in Kali (for example `ssh kali`), this starts it too:

```bash
chroot /proc/1/root /system/bin/sh /data/local/docker-on-android/start-docker.sh
```

Then use `docker` in the Kali chroot, for example over [SSH into Kali](04-ssh.md) (`ssh kali`) or in the NetHunter terminal:

```bash
docker run --rm hello-world
docker run -d -p 8088:80 nginx:alpine
```

Open it from the PC: `http://<phone-ip>:8088`.

## How it works

- `dockerd` runs in its own mount namespace (`unshare -m`). Android's `/data` mount is shared, and Docker's `pivot_root` fails under a shared mount. Inside the namespace the mounts are private. They never reach Android or the NetHunter app.
- In that namespace, Kali is bind-mounted at `/data/local/dockerroot`. Outside the namespace this folder looks empty. Inside, it IS Kali. Never delete it while Docker runs.
- The `cpuset` and `memory` cgroups are skipped. Android mounts cpuset with `noprefix`, and the kernel keeps that for every later mount. The kernel refuses a second memory mount. Docker works without both.
- Two `ip rule` entries keep `172.17.0.0/16` on `docker0`. Without them, Android's policy routing sends container traffic out over Wi-Fi.
- `--iptables=false`: Docker does not change Android's iptables. Bridge containers get no NAT, so they have no internet access. Published ports (`-p`) work, because `docker-proxy` is a local process.
- Two `FORWARD DROP` rules keep other devices on the LAN away from the container addresses.
- `--storage-driver=vfs`: overlayfs does not work here.

## Scripts

| Script | What it does | When to use |
|--------|--------------|-------------|
| `setup.sh` | Install `docker.io` and `docker-cli` in Kali | First time only |
| `start-docker.sh` | Start `dockerd` in its own mount namespace | After every reboot |
| `stop-docker.sh` | Stop all containers and `dockerd` | Full stop |
| `pause-docker.sh` | Remember the running containers, then stop | Save battery |
| `resume-docker.sh` | Start `dockerd` and the remembered containers | After a pause |
| `uninstall.sh` | Remove Docker from Kali. Kali stays | Remove Docker |

Run each script as root: `$ADB shell su -c 'sh /data/local/docker-on-android/<script>'`. The scripts are in [`docker/`](../docker).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Devices cgroup isn't mounted` | Use the custom kernel (`CONFIG_CGROUP_DEVICE=y`) |
| A container has no internet | Use `--network=host`. Bridge containers have no NAT |
| A published port does not answer | The process in the container must run as root or with a low UID. Android drops incoming connections to sockets of UID 10000 or higher. Try `--user 0` |
| `sudo` or other setuid programs fail in a container | `/data` is mounted `nosuid` |
| Docker DNS or TLS failures | `start-docker.sh` sets `GODEBUG=netdns=cgo`. Go's own DNS resolver fails on Android |
| Image pulls are slow | `vfs` copies every layer in full. There is no fix on Android |
