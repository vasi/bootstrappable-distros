# PTXdist

## Bootstrapping info

Upstream: https://www.ptxdist.org/doc/

Bootstrapping documentation:

* [PTXdist docs](https://www.ptxdist.org/doc/)
* [DistroKit](https://git.pengutronix.de/cgit/DistroKit/tree/doc/intro.rst)

Requirements: Linux with a compiler and some dev packages

Automation: Mostly automated, but need to fetch several sources

Integration testing: No

What you get: A minimal command-line system without dev tools

Can install further software from source: No

Why it doesn't count: No dev tools, no way to install software

## Manual testing

Version: 2025.05

Architecture: x86_64

Date: 2025-07-04

Build time: 6 hours on i7-9750H

### Testing process

* Using Fedora 42 host, but just to run a VM
  * Building in a Debian 12 VM, though a container might work as well
* Dependencies: `sudo apt install wget bzip2 gcc pkgconf libncurses-dev gawk flex bison texinfo unzip xz-utils make file patch git g++ zlib1g-dev libzstd-dev python3 python3-venv python3-dev rsync libgmp-dev libisl-dev libmpc-dev libssl-dev libcurl4-openssl-dev liblzma-dev bc`
* Build PTXdist
  * `cd ~`
  * `wget https://public.pengutronix.de/software/ptxdist/ptxdist-2025.05.0.tar.bz2`
  * `tar xf ptxdist-2025.05.0.tar.bz2`
  * `cd ptxdist-2025.05.0`
  * `./configure`
  * `make -j12`
  * `sudo make install`
* Fetch DistroKit, which describes the system we'll build
  * `git clone https://git.pengutronix.de/git/DistroKit -b DistroKit-2025.05.0 ~/DistroKit`
  * Figure out what toolchain we'll need: `grep CROSSCHAIN_VENDOR DistroKit/configs/platform-x86_64/platformconfig`
    * We need: OSELAS.Toolchain-2024.11.1
* [Build the toolchain](https://www.ptxdist.org/doc/environment.html#building-a-toolchain)
  * Setup PTXdist of the version matching the toolchain
    * `cd ~`
    * `wget https://public.pengutronix.de/oselas/toolchain/OSELAS.Toolchain-2024.11.1.tar.bz2`
    * Unpack and build as above. It's fine to have multiple versions of PTXbuild installed.
  * Fetch the toolchain
    * `cd ~`
    * `wget https://public.pengutronix.de/oselas/toolchain/OSELAS.Toolchain-2024.11.1.tar.bz2`
    * `tar xf OSELAS.Toolchain-2024.11.1.tar.bz2`
    * `cd OSELAS.Toolchain-2024.11.1`
  * Build it
    * `ptxdist-2024.11.0 select ptxconfigs/x86_64-unknown-linux-gnu_gcc-14.2.1_clang-19.1.7_glibc-2.40_binutils-2.43.1_kernel-6.11.6-sanitized.ptxconfig`
    * `ptxdist-2024.11.0 go`
    * `ptxdist-2024.11.0 make install`
* Build the "platform", aka distro
  * `cd ~/DistroKit`
  * `ptxdist-2025.05.0 platform configs/platform-x86_64/platformconfig`
  * `ptxdist-2025.05.0 images`
  * The image is in the platform-x86_64/images directory
* Run in qemu
  * `./configs/platform-x86_64/run`
  * Or alternatively, from the images directory: `qemu-system-x86_64 -accel kvm -m 2g -drive file=root.ext2,format=raw,if=virtio -kernel linuximage -append ' root=/dev/vda' -nographic`
  * There doesn't seem to be any package manager, or even a compiler
* Could we configure something a bit bigger?
  * Enter configurator: `ptxdist-2025.05.0 nconf`
  * There's options for building packages
  * But there don't seem to be any options for compilers on the target system
