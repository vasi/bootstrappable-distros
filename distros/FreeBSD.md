# FreeBSD

## Bootstrapping info

Upstream: https://www.freebsd.org/

Bootstrapping documentation: [Building on non-FreeBSD hosts](https://docs.freebsd.org/en/books/handbook/cutting-edge/#building-on-non-freebsd-hosts)

Requirements: Any POSIX with a C++ compiler, that can use ZFS

Automation: Partly automated

Integration testing: [CI job tests the kernel build](https://github.com/freebsd/freebsd-src/blob/main/.github/workflows/cross-bootstrap-tools.yml), but not the userland

What you get: Command-line base system

Can install further software from source: With [ports](https://docs.freebsd.org/en/books/handbook/ports/), or in bulk with [poudriere](https://github.com/freebsd/poudriere/wiki). May use binary components for some packages, such as Rust or JDK.

## Manual testing

Version: 14.2

Architecture: x86_64

Date: 2025-06-06

Build time: 5 hours with i5-10310U

### Testing process

* Using Arch Linux host. But it's just to run containers/VMs, you could use anything.
* Start a minimal Debian 12 container to build in: `docker run --name freebsd -ti debian:12`
  * `apt update`
  * `apt install git libarchive-dev libbz2-dev bzip2 clang cpp procps time xz-utils flex`
  * `git clone --depth=1 -b releng/14.2 https://git.freebsd.org/src.git freebsd`
  * `cd freebsd`
  * `mkdir /build` to hold object files
  * Build a toolchain and the userland: `MAKEOBJDIRPREFIX=/build tools/build/make.py -j9 TARGET=amd64 TARGET_ARCH=amd64 --bootstrap-toolchain buildworld`
  * Build the kernel: `MAKEOBJDIRPREFIX=/build tools/build/make.py -j9 TARGET=amd64 TARGET_ARCH=amd64 --bootstrap-toolchain buildkernel`
  * Install the world into a destdir: `MAKEOBJDIRPREFIX=/build tools/build/make.py -j9 TARGET=amd64 TARGET_ARCH=amd64 --bootstrap-toolchain DESTDIR=/dest installworld`
  * Install the kernel into a destdir: `MAKEOBJDIRPREFIX=/build tools/build/make.py -j9 TARGET=amd64 TARGET_ARCH=amd64 --bootstrap-toolchain DESTDIR=/dest installkernel`
  * Install config files: `MAKEOBJDIRPREFIX=/build tools/build/make.py -j9 TARGET=amd64 TARGET_ARCH=amd64 --bootstrap-toolchain DESTDIR=/dest distribution`
  * Unfortunately, the [release](https://man.freebsd.org/cgi/man.cgi?query=release&sektion=7&apropos=0&manpath=FreeBSD+14.3-RELEASE+and+Ports) targets that build artifacts like CD images don't work on Linux, and it seems reasonably hard to fix this.
  * We can use ZFS-on-Linux to deal with this, since Linux can write to it, and FreeBSD can boot from it. But for that we'll need a kernel with support, not just a container.
  * Exit the container, and copy /dest to somewhere outside: `docker cp freebsd:/dest ~/freebsd-stage0`
* Setup an VM to get access to ZFS.
  * I'll use Alpine 3.22's in Virt-Manager, but anything that supports ZFS should work, including your host machine
    * Add the Alpine "virtual" ISO for the install
    * Make the VM beefy, with as much RAM and CPU as possible, since we'll be building things in it
    * Make the VM use UEFI firmware (without secure boot), it'll be easier to boot FreeBSD that way
    * Add a SATA disk for Alpine, it can be small, 1 GB is likely fine
    * Add a SATA disk for FreeBSD, it should be at least 30 GB
  * Boot, login as root (no password), and run the Alpine installer: `setup-alpine`. Install on the first disk.
    * Make sure to setup a user, and ensure you can SSH in as that user
  * After rebooting, login as root
  * Allow SSH as root: `echo PermitRootLogin yes >> /etc/ssh/sshd_config; rc-service sshd restart`
  * Install ZFS: `apk add zfs zfs-lts`, then `modprobe zfs`
  * Partition the second disk
    * `apk add gptfdisk`
    * `gdisk /dev/sdb`
    * Add a 200 MB ESP partition, code ef00
    * Make the rest of the disk a ZFS filesystem, code a504
    * Write the partition table
  * Create a FAT filesystem on the ESP: `mkfs.vfat /dev/sdb1`
  * Mount the ESP: `mkdir /mnt/esp; modprobe vfat; mount /dev/sdb1 /mnt/esp`
  * Setup a ZFS pool: `zpool create -o altroot=/mnt zroot /dev/sdb2`
  * Copy our data to the pool from outside: `scp -r ~/freebsd-stage0/* root@alpine:/mnt/zroot`
  * Mount our ESP: `mkdir /mnt/esp; modprobe vfat; mount /dev/vdb1 /mnt/esp`
  * Copy the bootloader to the ESP: `mkdir -p /mnt/esp/EFI/freebsd; cp /mnt/zroot/boot/loader.efi /mnt/esp/EFI/freebsd/`
  * Shut down the VM
* Boot into our FreeBSD intermediate system
  * Configure the VM so only disk 2 is a boot drive
  * Boot the VM
  * At the EFI shell, type `fs0:\EFI\freebsd\loader.efi` to boot into the FreeBSD bootloader
  * In the bootloader, press Esc to get a boot shell. In the shell, type:
    * `load /boot/kernel/kernel`
    * `load /boot/kernel/zfs.ko` to enable ZFS
    * `boot -s` to boot into single-user mode
  * In single-user mode, fix some things up
    * Remove root as writable: `mount -uw /`
    * Set a time zone, eg: `ln -sf /usr/share/zoneinfo/Canada/Easter /etc/localtime`
    * Set a password with `passwd`
    * `exit` to continue to multi-user mode
  * Get a network connection: `dhclient vtnet0`
  * Edit /etc/ssh/sshd_config to enable root login
  * Start SSH: `/etc/rc.d/ssh onestart`
  * SSH in as root
  * Now we have an odd FreeBSD system. It has most files there, but some things are likely misconfigured, such as permissions. We'll use this to build a proper install ISO.
* In our odd FreeBSD system:
  * Copy our git checkout from our container to this system, from outside: `docker cp freebsd:/freebsd ~/freebsd-src; scp -r ~/freebsd-src root@freebsd:/usr/`
  * Back in SSH, rename it: `rmdir /usr/src; mv /usr/freebsd-src /usr/src; cd /usr/src`
  * Build the system: `make -j9 buildworld buildkernel`
  * Create install media: `make -C release dvdrom`, or `make -C release memstick` for USB
  * Copy /usr/obj/usr/src/amd64.amd64/release/dvd1.iso outside the VM
  * Shut down the odd FreeBSD VM, we're done with it
* We can now boot a VM, or real hardware, from the DVD image
  * It boots well in qemu, and installs successfully
* You can follow up with installing ports! Some complications for source-only installs:
  * You may want to disable the repo at `/etc/pkg/FreeBSD.conf`, which by default will download and install binaries
  * Fetching the ports tree typically uses git, but you won't have git until you build it from ports! Instead, you can grab a snapshot: `fetch https://download.freebsd.org/ftp/ports/ports/ports.tar.xz` and unpack it into /usr/ports.
    * Consider installing the `net/gitup` port for a no-dependencies way to fetch the ports tree.
  * When setting up poudriere, you'll need to point it at "installation sets" for initializing a jail. Thankfully, we already built some of those earlier, and they're on the DVD at the path `/usr/freebsd-dist`. You can copy them to your root filesystem, and setup a jail with `poudriere-jail -c -j default -m url=file:////usr/freebsd-dist`.
