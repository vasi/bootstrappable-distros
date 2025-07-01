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

Build time: About 1 day with i5-10310U

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
* Can we boot on real hardware?
  * Create a new partition on my EFI-booting ThinkPad T14s g1, format as ext4
  * Copy contents of boot.img (first partition) and root.img to the new ext4 partition
  * I already have rEFInd as a bootloader, so just setup a simple "refind_linux.conf" in the filesystem root, specifying the "root=/dev/..." flag for this partition
    * core/grub is also available in stagex, so we could probably use that
  * Fixup a few things before boot
    * Edit rcS to omit sdc stuff
    * Add some more ttys to inittab for convenience, with lines like "tty2::askfirst:-/bin/sh"
  * Reboot, and it comes up ok!
  * Change the network interface in rcS to the one I have plugged in
    * Run `dhcpcd $IFACE` to bring it up
    * Ping, wget work
  * Create a quick "stagex-install" script to automate the installation procedure above
    * Works great with user/tmux, though the dependencies (core/ncurses, user/libevent) need to be installed too
  * Let's bring up pkgsrc
    * Install some stagex dependencies first: core/gcc core/binutils core/gawk core/xz core/linux-headers
    * Clone pkgsrc git, and bootstrap (according to the pkgsrc docs). It works!
    * Can install nano, links, psmisc
    * Some things don't work out of the box, mostly due to musl issues, eg: lowdown, libbsd, llvm
