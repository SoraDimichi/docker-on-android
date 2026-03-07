# 3. Docker Setup

## Quick Start

```bash
su -c bash ~/setup.sh        # one-time: creates image, installs Debian + Docker
su -c bash ~/start-docker.sh  # after every reboot
```

Enter chroot and run nginx:

```bash
su -c "chroot /data/local/dockerroot /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin bash"
docker run -d --network=host nginx:alpine
```

Access from PC: `curl http://<phone-ip>:80`

## Scripts

| Script | What it does | When to use |
|--------|-------------|-------------|
| `setup.sh` | Create ext4 image, install Debian + Docker | First time only |
| `start-docker.sh` | Mount everything + start dockerd | After reboot |
| `stop-docker.sh` | Graceful shutdown + unmount + detach loop | Full teardown |
| `pause-docker.sh` | Stop all containers + stop dockerd (mounts stay) | Save battery, free resources |
| `resume-docker.sh` | Start dockerd + restart all containers | Wake up where you left off |
| `uninstall.sh` | Stop, unmount, delete image + chroot | Remove everything |

All scripts: `su -c bash ~/script.sh`

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Devices cgroup isn't mounted` | Need custom kernel with `CONFIG_CGROUP_DEVICE=y`, or cgroups not mounted |
| `remount /, flags: 0x84000` | Must use ext4 loop device, not /data directly |
| `cpuset/docker/cpuset.cpus: no such file` | Don't mount cpuset — Android's `noprefix` is cached by kernel, Docker works without it |
| `-p` port mapping not working | Use `--network=host` instead |
| Docker DNS/TLS failures | `GODEBUG=netdns=cgo` — Go's pure DNS resolver fails on Android |
| Image pulls very slow | `vfs` storage driver copies every layer fully — no fix on Android |
