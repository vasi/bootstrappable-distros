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

Why it doesn't count: Without package bootstrap, can't self-host

## Manual testing

Version: Git commit e6fc1b24, after R1 beta 5

Architecture: x86_64

Date: 2025-06-11

Build time: 25 minutes with i5-10310U

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
  * I was not able to complete this successfully, but here is as far as I got
  * Back in our container:
    * `apt install automake autoconf libncurses-dev cmake python2 autopoint pkg-config lzip`
    * `cd haiku`
    * `git clone --depth=1 https://github.com/haikuports/haikuporter`
    * `git clone --depth=1 https://github.com/haikuports/haikuports`
    * `git clone --depth=1 https://github.com/haikuports/haikuports.cross`
    * `cd /haiku/haiku; git clean -fxd :/`
    * `mkdir /haiku/bootstrap; cd /haiku/bootstrap`
    * `../haiku/configure --cross-tools-source ../buildtools --build-cross-tools x86_64 --bootstrap ../haikuporter/haikuporter ../haikuports.cross ../haikuports`
    * Fixup ICU:
      * In haikuports.cross/dev-libs/icu_bootstrap/icu_bootstrap-67.1.recipe, add `x86-64` to the ARCHITECTURES line
      * in haiku/Jamfile, where `icu74` is listed as a package, replace it with `icu`
    * `MAKEFLAGS= jam -q -sHAIKU_PORTER_CONCURRENT_JOBS=8 @bootstrap-raw`
      * If there are errors about tarballs failing to download, edit their download URLs in haikuports.cross
  * `docker cp haiku:/haiku/bootstrap/haiku-bootstrap.image haiku-bootstrap.img`
  * Run our image in qemu: `qemu-system-x86_64 -accel kvm -m 4G -drive file=haiku-bootstrap.img,format=raw`:
    * It boots successfully!
    * But now we want to run the Terminal app, and it doesn't run, nor does it emit an error.
  * I don't know enough about debugging Haiku to solve this, and it appears [CI has been disabled for months](https://github.com/haikuports/haikuports.cross/actions) on haikuports.cross
