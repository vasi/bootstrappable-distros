# Linux From Scratch

## Bootstrapping info

Upstream: https://www.linuxfromscratch.org/

Bootstrapping documentation: [LFS book](https://www.linuxfromscratch.org/lfs/view/stable/)

Requirements: [Any Linux with a C++ compiler and some common packages](https://www.linuxfromscratch.org/lfs/view/stable/chapter02/hostreqs.html)

Automation: Manual, though automation tools exist

Integration testing: None

What you get: A very basic command-line system

Can install further software from source: Only manually, for example with [Beyond LFS](https://www.linuxfromscratch.org/blfs/)

## Manual testing

Version: 12.3 (non-systemd)

Architecture: x86_64 

Date: 2025-06-05

Build time: 10 hours, for manually running commands

### Testing process

* LFS instructions are quite long, I've simply linked to the LFS book where it exactly describes the process
* Using Arch Linux host. But it's just to run docker, you could use anything.
* Create a disk image file:
    * `truncate -s 100g lfs.img`
    * Run `parted lfs.img`. Create a 200 MB ESP, a 10 MB BIOS Boot Partition, and the rest as an ext4 root:
        * `mklabel gpt`
        * `mkpart esp fat32 1m 201m`
        * `set 1 esp on`
        * `mkpart bbp 201m 201m`
        * `set 2 bios_grub on`
        * `mkpart lfs ext4 211m 100%`
    * Load partitions: `sudo partx -a lfs.img`. In my case, they're mounted as /dev/loop0p*
    * Make filesystems:
        * `sudo mkfs.vfat /dev/loop0p1`
        * `sudo mkfs.ext4 /dev/loop0p3`
    * Mount the root partition: `mkdir lfs; sudo mount /dev/loop0p3 lfs`
* Start a minimal Debian 12 container to build in: `docker run --name lfs -v $PWD/lfs:/mnt/lfs -ti debian`
* In container:
    * Install dependencies:
        * `apt update`
        * `apt install binutils bison gawk g++ make m4 patch python3 texinfo xz-utils wget`
        * Use bash as /bin/sh: `ln -sf bash /bin/sh`
        * Check we have all the dependencies with the [version check script](https://www.linuxfromscratch.org/lfs/view/stable/chapter02/hostreqs.html)
    * Setup root:
        * Setup the envar: `export LFS=/mnt/lfs`
        * Set umask: `umask 022`
        * Set permissions on root: `chown root:root $LFS; chmod 755 $LFS`
    * Fetch sources:
        * `wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv`
        * `wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources`
        * Expat could not be fetched, download its tarball manually
        * `wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums`
        * `pushd $LFS/sources; md5sum -c /md5sums; popd`
        * `chown root:root $LFS/sources/*`
    * Perform final preparation, following [chapter 4](https://www.linuxfromscratch.org/lfs/view/stable/chapter04/chapter04.html)
        * It's not really important to setup a user in a container, but we'll do it so we follow the book
    * Build the cross-toolchain, following [chapter 5](https://www.linuxfromscratch.org/lfs/view/stable/chapter05/chapter05.html)
    * Build temporary tools, following [chapter 6](https://www.linuxfromscratch.org/lfs/view/stable/chapter06/chapter06.html)
    * Setup the chroot, following [chapter 7](https://www.linuxfromscratch.org/lfs/view/stable/chapter07/introduction.html)
        * When [mounting virtual filesystems](https://www.linuxfromscratch.org/lfs/view/stable/chapter07/kernfs.html), do this from _outside_ docker
        * Then destroy the docker container
* Setup a chroot. Now that we have a chroot dir, no more need for a container.
    * Set `export LFS=$PWD/lfs`, and run the [chroot command](https://www.linuxfromscratch.org/lfs/view/stable/chapter07/chroot.html) as root
* In the chroot:
    * Continue with the rest of chapter 7, in the chroot
    * During the [backup stage](https://www.linuxfromscratch.org/lfs/view/stable/chapter07/cleanup.html), use zstd: `tar --zstd -cpf $HOME/lfs-temp-tools-12.3.tar.zst .`. It's much quicker!
        * After the backup, remount the virtual filesystems, and re-enter the chroot
    * Build the system software, following [chapter 8](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/chapter08.html)
    * Configure the system, following [chapter 9](https://www.linuxfromscratch.org/lfs/view/stable/chapter09/chapter09.html)
        * When [configuring the network](https://www.linuxfromscratch.org/lfs/view/stable/chapter09/network.html), adapt to qemu's network settings:
            * Device is `ens3`, not eth0
            * IP is `10.0.2.15`, and gateway is `10.0.2.2`
    * Make the system bootable, following [chapter 10](https://www.linuxfromscratch.org/lfs/view/stable/chapter10/chapter10.html)
        * We're using a disk image, so skip [installing grub](https://www.linuxfromscratch.org/lfs/view/stable/chapter10/grub.html) for now
    * [Setup release files](https://www.linuxfromscratch.org/lfs/view/stable/chapter11/theend.html)
* Test in qemu
    * Exit the chroot
    * Copy the kernel outside the image: `cp lfs/boot/vmlinuz* vmlinuz`
    * Unmount all filesystems: `sudo umount -R lfs`
    * Remove the kpartx mapping: `sudo kpartx -d lfs.img`
    * First, lets get grub working:
        * Run in qemu: `qemu-system-x86_64 -accel kvm -hda lfs.img -kernel vmlinuz -append 'root=/dev/sda3'`
        * [Setup grub.conf](https://www.linuxfromscratch.org/lfs/view/stable/chapter10/grub.html#grub-cfg):
            * Change the root to `(hd0,gpt3)` and `/dev/sda3`
            * Remove the `gfxpayload` line
        * Install grub: `grub-install /dev/sda`
        * `poweroff`
    * Restart with the internal kernel: `qemu-system-x86_64 -accel kvm -hda lfs.img`
        * It should boot up via grub!
* Can build more software with [Beyond LFS](https://www.linuxfromscratch.org/blfs/view/stable/)
