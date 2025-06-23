# toybox/mkroot

## Bootstrapping info

Upstream: https://landley.net/toybox/

Bootstrapping documentation: https://landley.net/toybox/faq.html#mkroot

Requirements: POSIX with C/C++ compiler and some tools

Automation: Mostly automated (make + scripts)

Integration testing: None

What you get: A minimal system

Can install further software from source: Only by hand

Why it doesn't count: Not a real distribution with package management

## Manual testing

Version: Git commit d6bc6b1d

Architecture: x86_64

Date: 2025-06-22

Build time: About one hour with i7-9750H

### Testing process

* Using Fedora 42 host. But it's just to run docker/podman, you could use anything
* Start a Debian 12 container to build in
  * `podman run --name toybox -ti debian:12`
  * `apt update`
  * `apt install git build-essential nano wget rsync flex bison bc libelf-dev libssl-dev squashfs-tools`
  * Continue inside the container
* Fetch source
  * `git clone https://github.com/landley/toybox.git`
  * `git clone https://github.com/richfelker/musl-cross-make.git`
  * `wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.15.3.tar.xz`
  * `tar -xf linux-6.15.3.tar.xz`
* Make some adjustments
  * Edit /toybox/scripts/mcm-buildall.sh. Remove all TARGETS except x86_64
  * Edit /musl-cross-make/Makefile. Remove savannah URL, replace with "https://cgit.git.savannah.gnu.org/cgit/config.git/plain/config.sub?id=$(CONFIG_SUB_REV)"
* Build musl toolchains
  * `cd /musl-cross-make`
  * `/toybox/scripts/mcm-buildall.sh`. Toolchains appear in "ccc"
  * `ln -s $(realpath ccc) ../toybox/ccc`
* Configure toybox
  * `cd /toybox`
  * `mkallyesconfig`
  * Disable things that don't build:
```
cp .config .config.old
cat <<EOF >.config.mod
CONFIG_TOYBOX_LIBZ=n
CONFIG_TOYBOX_LIBCRYPTO=n
CONFIG_GITCOMPAT=n
CONFIG_GITCLONE=n
CONFIG_GITINIT=n
CONFIG_GITREMOTE=n
CONFIG_GITFETCH=n
CONFIG_GITCHECKOUT=n
CONFIG_STRACE=n
CONFIG_SYSLOGD=n
EOF
cat .config.mod .config.old > .config
```
  * `mkdir /overlay`
  * `cp /musl-cross-make/ccc/x86_64-linux-musl-native.sqf /overlay/`
* Build a root: `mkroot/mkroot.sh CROSS=x86_64 LINUX=/linux-6.15.3 OVERLAY=/overlay overlay`
* Outside the container, run in qemu
  * `podman cp toybox:/toybox/root/x86_64 root`
  * `cd root`
  * `./run-qemu.sh`
  * In qemu:
    * `mount /x86_64-linux-musl-native.sqf /mnt`
    * `/mnt/bin/gcc` to run a compiler

