# OpenADK

## Bootstrapping info

Upstream: https://www.openadk.org/

Bootstrapping documentation: https://docs.openadk.org/html/manual.html

Requirements: Linux with a compiler

Automation: Mostly automated, some bug fixes required

Integration testing: No

What you get: A basic command-line system

Can install further software from source: Not effectively, opkg seems broken

Why it doesn't count: Broken package management, broken dev tools

## Manual testing

Version: Git commit 61e8fdc5

Architecture: x86_64

Date: 2025-06-30

Build time: 3 hours with i5-10310U

### Testing process

* Arch Linux host, but only to run VMs/docker
* We'll build in a Debian 12 docker container
  * `docker run --name openadk -ti debian:12`
  * `apt update`
  * `apt install gcc g++ make curl xz-utils libncurses-dev zlib1g-dev git libelf-dev python3 python3-cryptography wget pkgconf gpg`
* Get source
  * `git clone git://openadk.org/git/openadk /openadk`
  * `cd /openadk`
* Configure with `make menuconfig`
  * Hardware configuration
    * Architecture: x86_64
    * System: qemu emulator
    * Qemu system config
      * Bootloader: use bootloader
      * Graphical output: yes
      * VirtIO drivers: yes
  * Tasks: development appliance
  * Firmware configuration
  * Filesystem: Create a disk image
  * Package selection
    * Package options
      * Package format: opkg
  * Runtime configuration
    * Hostname: set to whatever you want
    * SSH public key: set to whatever you want
    * Timezone: set to what you want
    * Initial login shell for root: bash
  * Global settings
    * How many jobs: set to something reasonable for your system
* Fix various bugs
  * Fix root filesystem size, 64M is far too small
    * Edit target/x86_64/qemu-x86_64/genimage.cfg to make the root filesystem 5G in size
    * Edit mk/image.mk to similarly change 64M -> 5G
  * Fix boot with grub
    * Edit package/grub/files/grub-pc-vga.cfg to add root=/dev/sda1
    * Edit target/x86_64/kernel/qemu-x86_64 to set CONFIG_CMDLINE_OVERRIDE=n
  * Edit package/openssh/files/openssh-server.postinst set 'openssh YES'
  * Edit package/opkg/Makefile: Add zlib-host as HOST_BUILDDEP
  * Edit package/gpgme/Makefile: Add -fPIE to TARGET_CPPFLAGS
* Build with `make`
  * Got an error about fenv.h
    * Edit /openadk/build_qemu-x86_64_uclibc-ng/w-gcc-14.2.0-1/gcc-obj/x86_64-openadk-linux-uclibc/libstdc++-v3/config.h and remove the HAVE_FENV_H "#define". There's probably a better way to fix the detection, but I'm not sure what.
* Boot the system, from outside docker
  * `docker cp openadk:/openadk/firmware/qemu-x86_64_uclibc-ng/disk.img openadk.img`
  * `qemu-system-x86_64 -accel kvm -M pc -m 2g -vga std -net nic,model=virtio -net user,hostfwd=tcp::2222-:22 -drive file=openadk.img,format=raw`
  * Login with root/linux123
  * There's some kind of /etc-repo used, so need to `cfgfs commit` before reboot to save the host SSH keys
  * The root FS is read-only! This kinda makes sense with the "cfgfs" system, but not if home-dirs are now read-only too. Fix with `mount -o remount,rw /`, and also add root to fstab with "remount,rw" options
* What's package management like?
  * `opkg list` and similar commands don't print any output. Even `opkg print-architecture` does nothing
  * But inside docker, we do have some '.ipkg' files in debian-ish format in "firmware/qemu-x86_64_uclibc-ng/packages/"
    * Copy them out of docker, and serve with `python -m http.server 8080`
    * In VM, create "/etc/opkg/opkg.conf":

          dest root /
          arch x86_64 1
          src base http://10.0.2.2:8080

    * We can `opkg update` and `opkg list`!
    * No packages are considered installed
    * Attempting to install a package hangs
    * We could try to investigate, but some devtools seem broken. Eg: "ar" won't run, says it's missing a libfl.so
  * Calling this too broken to actually support package building or installation
