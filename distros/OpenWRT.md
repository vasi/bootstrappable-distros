# OpenWRT

## Bootstrapping info

Upstream: https://openwrt.org/

Bootstrapping documentation: 
* [Build guide](https://openwrt.org/docs/guide-developer/toolchain/beginners-build-guide)
* [Self-hosting](https://openwrt.org/docs/guide-developer/toolchain/building_openwrt_on_openwrt)
* [Building one package](https://openwrt.org/docs/guide-developer/toolchain/single.package)

Requirements: POSIX with compilers and a bunch of packages

Automation: Mostly automated

Integration testing: [Github Actions](https://github.com/openwrt/openwrt/tree/main/.github/workflows)

What you get: An embedded router OS, plus whatever packages you want

Can install further software from source: Yes

## Manual testing

Version: 24.01

Architecture: x86_64

Date: 2025-07-11

Build time:
* 40 minutes on i7-9750H to get a minimal bootable image
* 2 more hours to achieve self-building of packages

### Testing process

* Using Fedora 42 host, building in a Debian 12 VM
* Dependencies: `sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev python3-distutils python3-setuptools rsync swig unzip zlib1g-dev file wget`
* Get source and package definitions
  * `git clone https://git.openwrt.org/openwrt/openwrt.git -b openwrt-24.10`
  * `cd openwrt`
  * `./scripts/feeds update -a`
  * `./scripts/feeds install -a`
* Configure
  * `make menuconfig`. Choose:
    * Target: x86
    * Subtarget: x86_64
* Fetch sources: `make download`
* Build: `make -j12`
  * Creates bin/targets/x86/64/openwrt-x86-64-generic-ext4-combined.img.gz
* Run
  * Copy img.gz somewhere
  * `gunzip openwrt-x86-64-generic-ext4-combined.img.gz`
  * `qemu-system-x86_64 -accel kvm -m 4g -drive file=openwrt-x86-64-generic-ext4-combined.img,format=raw -device virtio-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2222-:22`
  * Get on the network, in qemu:
    * `uci set network.lan.proto=dhcp`
    * `uci commit network`
    * `service network restart`
  * SSH in: `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost`
  * Can install binary packages
    * `opkg update`
    * `opkg install ncdu`
* Build with target dev tools
  * We'll pick tools sufficient to self-host
  * `make menuconfig`. Choose:
    * Administration: htop
    * Target Images Root filesystem partition size: 2000
    * Development: autoconf automake diffutils gcc libtool-bin make patch pkg-config
      * Libraries: libncurses-dev zlib-dev
    * Languages
      * Perl: perl perlbase-b perlbase-extutils perlbase-feature perlbase-findbin perlbase-ipc perlbase-json-pp perlbase-module perlbase-pod perlbase-storable perlbase-time
      * Python: python3
    * Libraries: check musl-fts
      * Compression: libzstd
    * Network
      * File Transfer: rsync wget-ssl
      * Version Control: git git-http
    * Utilities: coreutils-cksum coreutils-comm coreutils-cp coreutils-csplit coreutils-date coreutils-expr coreutils-install coreutils-join coreutils-ln coreutils-ls coreutils-mkdir coreutils-nohup coreutils-nproc coreutils-od coreutils-printf coreutils-realpath coreutils-sort coreutils-split coreutils-stat coreutils-test coreutils-tr coreutils-uniq file findutils findutils-locate flock gawk getopt grep less sed tar whereis xxd
      * Compression: bzip2 gzip unzip
        * xz-utils: xz
      * Editors: nano
      * Filesystem: chattr lsattr
      * Shells: bash
      * procps-ng: procps-ng-ps
  * `make -j12`
  * Copy the filesystem image, as before
* Build a package locally
  * Setup
    * Create an auxiliary virtual disk to store our build
    * Run in qemu/libvirt, maxing out the RAM and CPUs, and adding our new disk
    * From now on, run commands within qemu
    * `mkfs.ext4 /dev/vdb`
    * `mount /dev/vdb /mnt`
  * Fetch source
    * `git clone https://git.openwrt.org/openwrt/openwrt.git -b openwrt-24.10 /mnt/openwrt`
    * `cd /mnt/openwrt`
    * `./scripts/feeds update -a`
    * `./scripts/feeds install -a`
  * Install missing dependencies
    * Symlink a library
      `ln -s libncursesw.a /usr/lib/libncurses.a`
    * Create stub libraries
      * `ar -rc /usr/lib/libdl.a`
      * `ar -rc /usr/lib/librt.a`
      * `ar -rc /usr/lib/libpthread.a`
      * `ar -rc /usr/lib/libresolv.a`
    * Symlink tools
      * `ln -s bzip2 /bin/bzcat`
      * `ln -s bzip2 /bin/bunzip2`
    * Build argp 
      * `cd /mnt`
      * `git clone git clone https://github.com/xhebox/libuargp.git`
      * `cd libuargp`
      * `make -j12`
      * `make prefix=/usr install`
    * Build fts for musl
      * `cd /mnt`
      * `git clone https://github.com/void-linux/musl-fts.git`
      * `cd musl-fts`
      * `./bootstrap.sh`
      * `./configure --prefix=/usr`
      * `make -j12`
      * `make install`
    * Build obstack for musl
      * `cd /mnt`
      * `git clone https://github.com/void-linux/musl-obstack.git`
      * `cd musl-obstack`
      * `./bootstrap.sh`
      * `./configure --prefix=/usr`
      * `make -j12`
      * `make`
      * `make install`
  * Configure: `make menuconfig`. Choose:
    * Target x86
    * Subtarget x86_64
    * Select a package we want, eg: Utilities/Filesystem/ncdu
  * Build the package
    * `export FORCE_UNSAFE_CONFIGURE=1`
    * `make -j12 tools/install`
    * `make -j12 toolchain/install`
    * `make -j12 package/ncdu/compile`
  * Install it: `opkg install bin/packages/x86_64/packages/ncdu_1.20-r1_x86_64.ipk`
