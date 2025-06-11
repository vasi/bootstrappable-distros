# Sabotage

## Bootstrapping info

Upstream: http://sabo.xyz/

Bootstrapping documentation: [Native build instructions](https://codeberg.org/sabotage-linux/sabotage/src/branch/master/README.md#native-build-instructions)

Requirements: Any Linux 2.6+ with a C compiler

Automation: Mostly automated

Integration testing: None

What you get: A minimal command-line distro

Can install further software from source: Yes, with the `butch` minimal package manager. Not many packages, and they're often quite old.

## Manual testing

Version: Git commit deb0218143, as of 2025-06-07

Architecture: x86_64

Date: 2025-06-07

Build time: 45 minutes with i5-10310U

### Testing process

* Using Arch Linux host. But it's just to run VMs, you could use anything.
* Start a minimal Alpine Linux 3.22 container to build in: `docker run --name sabo -ti alpine:3.22`
* In container
    * `apk add gcc musl-dev make git`
    * `git clone https://codeberg.org/sabotage-linux/sabotage.git`
    * `cd sabotage`
    * `cp KEEP/config.stage0 config`
    * `./create-minimal-rootfs`, to create a tiny ~20 MB rootfs in /tmp/sabotage
* Swap from the container to the chroot
    * There's a few ways to do this, depending on your host system. Let's use the `enter-chroot` script, in root mode:
        * Modify the enter-chroot script so it works in chroot-mode instead of with namespaces: `perl -i -pe 's,-d /proc/self/ns,! $&,' enter-chroot`
        * `mkdir -p tarballs`
        * `cp KEEP/config.stage0 config`
        * `perl -i -pe "s,(export SABOTAGE_BUILDDIR=).*,\$1$PWD/../sabotage-root," config`
        * `docker cp sabo:/tmp/sabotage ../sabotage-root`
        * `sudo ./enter-chroot boot.sh`
    * In the chroot, run `/src/utils/boot-stage0.sh`
    * Exit the chroot, this will take two `exit` commands since we're in a sub-shell
* Re-enter the chroot, eg: with `sudo ./enter-chroot sh`
    * `butch install stage1`
    * To make the system reproducible:
        * `/src/utils/clean-stage1.sh`
        * `/src/utils/rebuild-stage1.sh`
    * `butch install kernel`
* Build an image, still in the chroot
    * `butch install syslinux6 rsync util-linux`
    * `rm -rf /src/build` to cleanup build artifacts
    * `rsync --archive --one-file-system --exclude /rootfs / /rootfs`, to copy the root to a directory. Ignore errors about mountpoints.
    * `/src/utils/root-perms.sh /rootfs` to fix permissions
    * Work around some bugs:
        * Syslinux data in the wrong place: `ln -s /lib/syslinux/bios /usr/share/syslinux`
        * util-linux's mount refusing to work: `perl -i -pe 's/\b(u?mount)\b "/busybox $1 "/' /src/utils/write-hd-image.sh`
        * Taking way too long on large images: `perl -i -pe 's/^(imagesize_in_bytes=).*/$1\$(stat -c %s \$imagefile)/' /src/utils/write-hd-image.sh`
    * `/src/utils/write-hd-image.sh /sabo.img /rootfs 30G`
    * Exit the chroot, and copy the image somewhere useful
* Image runs in qemu: `qemu-system-x86_64 -m 2g -accel kvm -hda sabo.img`
