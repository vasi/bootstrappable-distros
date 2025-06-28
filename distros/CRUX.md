# CRUX

## Bootstrapping info

Upstream: https://crux.nu/

Bootstrapping documentation: https://crux.nu/Wiki/OfficialISOBuildProcess

Requirements: Linux, and a very large number of packages

Automation: With make

Integration testing: No

What you get: Unknown, it failed

Can install further software from source: Probably, with ports

Why it doesn't count: Bootstrapping has too many bugs

## Manual testing

Version: 3.8

Architecture: x86_64

Date: 2025-06-27

Build time: Incomplete

### Testing process

* Arch Linux host, but only to run VMs
  * The build process will need to modify the root filesystem, so it should be disposable
  * We'll run a Debian 12 VM
  * Everything below should be run as root!
* Dependencies: `apt install git links syslinux make g++ libarchive-dev pkgconf nettle-dev libxml2-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev liblzma-dev libacl1-dev libelf-dev txt2man curl xz-utils flex bison bc libssl-dev libarchive-tools autoconf libncurses-dev ninja-build libuv1-dev librhash-dev libjsoncpp-dev libcurl4-openssl-dev libexpat1-dev file libudev-dev libpam0g-dev uuid-dev libblkid-dev gperf libkmod-dev libpcre2-dev libdb5.3-dev libmpfr-dev libmpc-dev libc6-dev-i386 rsync python3 libmnl-dev meson libbsd-dev cmake`
* Build some distro tools
  * `git clone https://git.crux.nu/tools/pkgutils.git ~/pkgutils`
    * `cd ~/pkgutils`
    * `make`
    * `make install`
  * `git clone https://git.crux.nu/tools/prt-utils.git ~/prt-utils`
    * `cd ~/prt-utils`
    * `make install`
* Get ports
  * `git clone -b 3.8 http://git.crux.nu/system/iso.git /usr/src/iso`
  * `git clone -b 3.8 http://git.crux.nu/ports/core.git /usr/src/iso/ports/core`
  * `git clone -b 3.8 http://git.crux.nu/ports/opt.git /usr/src/iso/ports/opt`
  * `git clone -b 3.8 http://git.crux.nu/ports/xorg.git /usr/src/iso/ports/xorg`
  * `cd /usr/src/iso`
  * `prtwash ports/*/*`
* Build signify with CRUX patch
  * `cd ~`
  * `curl -LO https://github.com/leahneukirchen/outils/archive/v0.14/outils-0.14.tar.gz`
  * `tar xf outils-0.14.tar.gz`
  * `cd outils-0.14`
  * `patch -p1 < /usr/src/iso/ports/core/signify/cruxify.patch`
  * `make CFLAGS+=' -DSIGNIFYROOT="\"/etc/ports\""' PREFIX=/usr src/usr.bin/signify/signify`
  * `cp src/usr.bin/signify/signify /usr/bin/`
  * Copy keys into place
    * `mkdir -p /etc/ports`
    * `cp -r /usr/src/iso/ports/core/ports /etc/`
* Setup for build
  * `cd /usr/src/iso`
  * `make -B packages.all`
  * Build docs: `(cd doc/handbook; ./get_wiki_handbook; ./get_wiki_release_notes)`
* Attempt to bootstrap!
  * `make bootstrap`
* So many things break
  * One package needs a dhcp user, create it: `useradd dhcpcd`
  * Some packages need newer versions of libftnl, so get them from testing:
    * `echo 'deb http://deb.debian.org/debian/ trixie main non-free-firmware' > /etc/apt/sources.list.d/testing.list`
    * `echo 'APT::Default-Release "stable";' > /etc/apt/apt.conf.d/99default`
    * `apt install -t testing libnftnl-dev`
  * Several packages expect the dynamic linker to live in /lib, so create a symlink: `ln -s /lib64/ld-linux-x86-64.so.2 /lib/`
  * Several packages use meson, which believes libdir should be /usr/lib/x86_64-linux-gnu, but CRUX disagrees. Add a hack to fix this, editing /usr/lib/python3/dist-packages/mesonbuild/utils/universal.py . Change "defaul_libdir()" to always "return 'lib'"
  * httpup links "-lcurl" too early, edit the Pkgfile to fix: `perl -i -pe 's/-o .*/$& -lcurl/' Makefile`
  * kbd attempts to use strlcpy, so needs to have `LDFLAGS=-lbsd` added to the Pkgfile
  * libarchive has the wrong permissions on a file, causing a footprint error
  * libcap needs `LIBDIR=/lib`
  * Each time a Pkgfile or patch is modified, it breaks the signature validation. Need to build that port in particular with `cd /usr/src/iso/ports/core/$port; PORTS_DIR=/usr/src/iso/ports /usr/bin/pkgmk -cf /usr/src/iso/pkgmk.conf -d -is`
* Overall, this is just too many errors to deal with one at a time.
  * These erorrs are from less than half of stage0, and there's two more stages to go.
  * It's fundamentally not safe to be building all these packages with the host toolchain, they'll definitely break once we try to enter a chroot for stage1.
