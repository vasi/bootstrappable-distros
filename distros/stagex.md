# stagex

## Bootstrapping info

Upstream: https://stagex.tools/

Bootstrapping documentation: https://codeberg.org/stagex/stagex#reproduce-entire-tree

Requirements: Anything that can run Docker

Automation: Building containers is automated, but treating it as a distro needs manual work

Integration testing: [Yes, in Codeberg](https://codeberg.org/stagex/stagex/actions?workflow=merge-main-check.yml&actor=0&status=0)

What you get: A collection of containers that can be turned into a distro

Can install further software from source: A few hundred packages, as buildable containers

## Manual testing

Version: Git commit 9212430f

Architecture: x86_64

Date: 2025-06-18

Build time: About 1 day

### Testing process

* Using Arch Linux host
* Install dependencies: `pacman -S git make docker python`
* [Switch to containerd](https://docs.docker.com/engine/storage/containerd/#enable-containerd-image-store-on-docker-engine)
  * `sudo mkdir -p /etc/docker`
  * As root, edit or create /etc/docker/daemon.json, so it has the key `{"features": {"containerd-snapshotter": true}}`
  * Restart docker, eg: `sudo systemctl restart docker`
* Clone our repos
  * stagex has the basic packages: `git clone https://codeberg.org/stagex/stagex.git`
* Build stagex
  * `cd stagex`
  * Change the mirrors URL in packages/user/acpica/package.toml to something that resolves, eg: `https://www.coreboot.org/releases/crossgcc-sources/acpica-unix-{version}.{format}`
  * Bootstrap up from live-bootstrap: `make IMPORT=1 bootstrap-stage3`
* Turn this into something distro-like
  * It's now just a bunch of containers, but it's not hard to make it bootable
  * I built a quick demo of a bootable distro with [stagex-boot](https://github.com/vasi/stagex-boot), but there's also [Airgap](https://git.distrust.co/public/airgap) and [ReprOS](https://codeberg.org/stagex/repros)
  * `cd ..` to exit the stagex repo
  * `git clone https://github.com/vasi/stagex-boot/`
  * `make run` to build the requisite packages, turn them into a VM image, and run it with qemu
  * `make ssh` to SSH in
* Our VM is now self-hosting, and can build packages
  * `git clone https://codeberg.org/stagex/stagex.git /build/stagex`
  * `cd /build/stagex`
  * `make IMPORT=1 bootstrap/stage3`
  * We can then run the images produced
* We can kinda "install" these packages by copying their contents. Eg: for mtools:
  * `make IMPORT=1 user-mtools`
  * `mkdir /mnt`
  * `ctr -a /var/run/docker/containerd/containerd.sock -n moby image mount docker.io/stagex/user-mtools:local /mnt`
  * `cp -a /mnt/* /`
  * `umount /mnt`
