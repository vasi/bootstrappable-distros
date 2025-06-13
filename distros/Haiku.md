# Haiku

## Bootstrapping info

Upstream: https://www.haiku-os.org/

Bootstrapping documentation:
* [Prerequisites](https://www.haiku-os.org/guides/building/pre-reqs)
* [Extended attributes](https://www.haiku-os.org/guides/building/configure/use-xattr)
* [Getting the source](https://www.haiku-os.org/guides/building/configure/use-xattr)
* [Compiling](https://www.haiku-os.org/guides/building/compiling-x86_64)
* [Bootstrapping a new architecture](https://www.haiku-os.org/docs/develop/packages/Bootstrapping.html)

Requirements: Most modern Unixes, with a C compiler and some common tools

Automation: Mostly automated

Integration testing: [Yes](https://ci.haiku-os.org/)

What you get: A full Haiku desktop! But without development tools

Can install further software from source: Not easily, but maybe you can figure out the bootstrap procedure below.

## Manual testing

Version: Git commit e6fc1b24, after R1 beta 5

Architecture: x86_64

Date: 2025-06-11

Build time: 25 minutes

### Testing process

* Using Arch Linux host. But it's just to run docker, you could use anything.
* Use a Debian 11 container to [create an XFS filesystem for building Haiku](https://www.haiku-os.org/guides/building/configure/use-xattr):
  * We're using Debian 11 because it still has Python 2, which we need for the bootstrapping step later
  * `mkdir -p haiku/img`
  * `docker run --name haiku-fs -v $PWD/haiku/img:/img -ti debian:12`
  * In the container:
    * `apt update`
    * `apt install xfsprogs`
    * `fallocate -l 20g /img/haiku.img`
    * `mkfs.xfs /img/haiku.img`
    * Exit the container
* Create a Debian 11 container for the build
  * `mkdir -p haiku/mnt`
  * `sudo modprobe xfs`
  * `sudo mount haiku/img/haiku.img haiku/mnt`
  * `docker run --name haiku -v $PWD/haiku/mnt:/haiku -ti debian:12`
  * In the container:
    * `apt update`
    * `apt install git nasm bc autoconf automake texinfo flex bison gawk build-essential unzip wget zip less zlib1g-dev libzstd-dev xorriso libtool gcc-multilib python3 attr`
    * `cd /haiku`
    * `git clone --depth=1 https://review.haiku-os.org/buildtools`
    * `git clone --depth=1 https://review.haiku-os.org/haiku`
    * `export MAKEFLAGS=-j8`
    * Build the jam build tool:
      * `cd /haiku/buildtools/jam`
      * `make`
      * `./jam0 install`
    * Build a toolchain:
      * `cd /haiku/haiku`
      * `./configure --cross-tools-source ../buildtools --build-cross-tools x86_64`
    * Build Haiku: `jam -q -j8 @nightly-raw`
    * Exit the container
* `docker cp haiku:/haiku/haiku/generated/haiku-nightly.image haiku-nightly.image`
* Test in qemu:
  * `qemu-img create -f qcow2 haiku.qcow2 20g`
  * `qemu-system-x86_64 -accel kvm -m 4G -drive file=haiku-nightly.image,format=raw -drive file=haiku.qcow2`
  * Run the installer app. Create a BeFS partition, and install on it
  * Shutdown qemu, then restart with just the drive: `qemu-system-x86_64 -accel kvm -m 4G -drive file=haiku.qcow2`
  * Can install binary packages with HaikuDepot
* To install more source packages without binaries, we need a special [bootstrap build](https://www.haiku-os.org/docs/develop/packages/Bootstrapping.html)
  * But I wasn't able to get this to build and yield something bootable.It looks like [CI on haikuports.cross has been disabled for months](https://github.com/haikuports/haikuports.cross/actions).
