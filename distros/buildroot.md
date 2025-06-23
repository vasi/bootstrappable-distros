# buildroot

## Bootstrapping info

Upstream: https://buildroot.org/

Bootstrapping documentation: https://buildroot.org/downloads/manual/manual.html#writing-genimage-cfg

Requirements: Any Linux with a compiler and some common tools

Automation: Mostly automated (make + scripts), but need to modify config and create image manually

Integration testing: [CI on Gitlab](https://gitlab.com/buildroot.org/buildroot/pipelines)

What you get: A small system, with any packages you select at build-time

Can install further software from source: No, there's no compiler on the target

Why it doesn't count: Not self-hosting

## Manual testing

Version: 2025.05

Architecture: x86_64

Date: 2025-06-13

Build time: 35 minutes with i5-10310U

### Testing process

* Using Arch Linux host. But it's just to run docker, you could use anything.
* Setup a Debian 12 container to build in: `docker run --name buildroot -ti debian:12`
* In the container:
  * Setup dependencies:
    * `apt update`
    * `apt install -y build-essential cpio rsync bc wget git libncurses-dev libelf-dev`
  * Create a user for buildroot:
    * `useradd -ms /bin/bash buildroot`
    * `su - buildroot`
  * Fetch source:
    * `wget https://buildroot.org/downloads/buildroot-2025.05.tar.gz`
    * `tar -xvf buildroot-2025.05.tar.gz; cd buildroot-2025.05`
  * Configure:
    * `cp configs/qemu_x86_64_defconfig .config`
    * `make nconfig`
    * System configuration:
      * Root password: set anything you like
      * Custom scripts to run before creating filesystem images: delete this
    * Kernel: Install kernel to /boot
    * Filesystem images: Set ext2 size to a reasonable amount, eg: 2G
    * Host utilities:
      * Enable host genimage
      * Disable host qemu
    * Bootloaders: grub2, and select 'install tools'
    * Save and exit the configuration
    * Modify the kernel config:
      * `printf 'CONFIG_DRM_FBDEV_EMULATION=y\nCONFIG_FRAMEBUFFER_CONSOLE=y\n' >> board/qemu/x86_64/linux.config`
  * Build: `make`
  * Build the image:
    * `ln -f --target=. output/images/rootfs.ext2 output/images/grub.img output/target/lib/grub/i386-pc/boot.img`
    * `./output/host/bin/genimage --inputpath . --outputpath . --config board/pc/genimage-bios.cfg`
* Test in qemu:
  * Exit the container
  * `docker cp buildroot:/home/buildroot/buildroot-2025.05/disk.img .`
  * `qemu-system-x86_64 -accel kvm -drive file=disk.img,format=raw -net nic,model=virtio -net user`
