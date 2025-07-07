# LibreELEC

## Bootstrapping info

Upstream: https://libreelec.tv/

Bootstrapping documentation: https://wiki.libreelec.tv/development/build-basics

Requirements: Linux with a compiler and many packages. Only tested on Ubuntu

Automation: Yes, with some shell scripts

Integration testing: [Github Actions](https://github.com/LibreELEC/actions)

What you get: A graphical HTPC interface

Can install further software from source: No

Why it doesn't count: No dev tools or package management

## Manual testing

Version: 12.02

Architecture: x86_64

Date: 2025-07-05

Build time: 10 hours on i7-9750H

### Testing process

* Normally I might not test a a single-purpose appliance distro, but it looks like there's a [gcc package](https://github.com/LibreELEC/LibreELEC.tv/tree/master/packages/lang/gcc)
* Using Fedora 42 host, but only to run containers
  * There's a [container definition](https://github.com/LibreELEC/LibreELEC.tv/blob/master/tools/docker/jammy/Dockerfile) for building LibreELEC
* Setup an Ubuntu 22.04 container
  * `podman run --name libreelec -ti ubuntu:22.04`
  * `apt update`
  * `apt install -y --no-install-recommends sudo locales curl bash bc gcc-12 sed patch patchutils tar bzip2 gzip xz-utils zstd perl gawk gperf zip unzip diffutils lzop make file g++-12 xfonts-utils xsltproc default-jre-headless python3 libc6-dev libncurses5-dev libjson-perl libxml-parser-perl libparse-yapp-perl rdfind golang-1.22-go git openssh-client rsync wget`
  * `locale-gen en_US.UTF-8`
  * `update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 --slave /usr/bin/cpp cpp /usr/bin/cpp-12 --slave /usr/bin/g++ g++ /usr/bin/g++-12 --slave /usr/bin/gcov gcov /usr/bin/gcov-12`
  * `ln -s /usr/lib/go-1.22 /usr/lib/go && ln -s /usr/lib/go-1.22/bin/go /usr/bin/go && ln -s /usr/lib/go-1.22/bin/gofmt /usr/bin/gofmt`
* Setup a user
  * `useradd -m build -G sudo -s /bin/bash`
  * `echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers`
  * `su - build`
* Get the source
  * `git clone https://github.com/LibreELEC/LibreELEC.tv.git -b 12.0.2 ~/LibreELEC.tv`
  * `cd ~/LibreELEC.tv`
* Download sources
  * `PROJECT=Generic ARCH=x86_64 tools/download-tool`
  * If anything fails, find it elsewhere
  * If any sha256 checksums are wrong, fix them
* Build
  * `PROJECT=Generic ARCH=x86_64 LOGCOMBINE=fail MTPROGRESS=yes make image`
  * Builds file target/LibreELEC-Generic.x86_64-12.0-devel-20250706064803-f3fdd11.img.gz
* Run
  * `podman cp libreelec:/home/build/LibreELEC.tv/target/LibreELEC-Generic.x86_64-12.0-devel-20250706064803-f3fdd11.img.gz .`
  * `gunzip /home/build/LibreELEC.tv/target/LibreELEC-Generic.x86_64-12.0-devel-20250706064803-f3fdd11.img.gz`
  * Try qemu
    * `qemu-system-x86_64 -accel kvm -m 8g -smp 4 -drive file=le.qcow2 -drive file=LibreELEC-Generic.x86_64-12.0-devel-20250706064803-f3fdd11.img,format=raw -boot menu=on`
    * Choose second disk at boot menu, then 'installer' at bootloader, then install
    * Boots, but no graphical or text console shows up
  * Try on real hardware
    * Boots up to Kodi!
    * But I don't see any dev tools
  * It seems although there's a GCC package for the target, it only installs libraries, not an actual compiler
