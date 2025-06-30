# stal/IX

## Bootstrapping info

Upstream: https://stal-ix.github.io/

Bootstrapping documentation: https://stal-ix.github.io/INSTALL_SOURCE.html

Requirements: Linux with a C/C++ compiler

Automation: Limited, many manual steps

Integration testing: None

What you get: Unknown, it doesn't work

Can install further software from source: Probably, with IX

Why it doesn't count: Bootstrapping fails on first reboot

## Manual testing

Version: Git commit dab8696

Architecture: x86_64

Date: 2025-06-25

Build time: Incomplete after 16 hours

### Testing process

* It looks like stal/IX makes use of bwrap, so it'll be easiest to run in a VM
  * Using Arch Linux host, but just to run VMs
  * Setup Debian 12 VM
* Disk setup
  * Add a disk vdb to VM, boot it
  * Switch to root shell: `sudo -i`
  * `apt install parted g++ git make python3 wget xz-utils`
  * Create a GPT setup on vdb with parted: BBP, swap, ext4 root. Create filesystems
  * `mkdir /mnt/ix`
  * `mount /dev/vdb3 /mnt/ix`
  * `cd /mnt/ix`
  * `ln -s ix/realm/system/bin bin`
  * `ln -s ix/realm/system/etc etc`
  * `ln -s / usr`
  * `mkdir -p home/root var sys proc dev tmp`
  * `ln -s /mnt/ix/ix /ix`
* User setup
  * `useradd -ou 1000 ix`
  * `mkdir ix`
  * `chown ix ix`
  * `mkdir home/ix`
  * `chown ix home/ix`
  * `su ix`
  * `cd /mnt/ix`
* Package manager setup
  *`(cd home/ix; git clone https://github.com/stal-ix/ix.git)` (commit dab8696)
  * `mkdir -m 01777 ix/realm`
Bootstrap tools
  * `cd home/ix/ix`
  * `export IX_ROOT=/ix`
  * `export IX_EXEC_KIND=local`
  * `./ix mut system set/stalix --failsafe etc/zram/0`
  * `./ix mut root set/install`
    * Hit this issue: https://github.com/stal-ix/ix/issues/744
    Cherry pick https://github.com/pg83/ix/commit/2d174b21299cd0431c6d95b4c395a695530e078a
  * `./ix mut boot set/boot/all`
* [Build a kernel](https://stal-ix.github.io/KERNEL.html)
  * `export PATH=/mnt/ix/home/ix/ix:${PATH}`
  * `mkdir ~/kernel`
  * `cd ~/kernel`
  * `grep 6.15 $(dirname $(which ix))/pkgs/bin/kernel/6/15/ver.sh` yields 6.15.3
  * `wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.15.3.tar.xz`
  * `tar xf linux-6.15.3.tar.xz`
  * `cd linux-6.15.3`
  * `cp $(dirname $(which ix))/pkgs/bin/kernel/configs/cfg_6_14 ./.config`
  * `ix run set/menuconfig -- make HOSTCC=cc CC=cc LD=ld.lld menuconfig`
    * [Disable EFI_STUB](https://github.com/stal-ix/ix/issues/754)
    * Otherwise we're just enabling the options corresponding to loaded modules in our Debian kernel and/or lsci/lsusb in our VM
      * Disable PREEMPT_RT
    * Enable TRANSPARENT_HUGEPAGE
    * Enable VIRT_DRIVERS, VIRTUALIZATION, KVM, KVM_INTEL
    * Enable VIRTIO_DRIVERS, VIRTIO_PCI, DRM_VIRTIO_GPU, VIRTIO_BALLOON, VIRTIO_CONSOLE, FW_CFG_SYSFS, HW_RANDOM_VIRTIO, VIRTIO_NET, VIRTIO_BLK, SCSI_VIRTIO, VIRTIO_INPUT
    * Enable INTEL_VSEC, INTEL_PMT_TELEMETRY, INTEL_PMC_CORE
    * Enable SERIO_RAW, BLK_DEV_DM, CONFIGFS_FS, AUTOFS_FS, NETFILTER, IP_NF_IPTABLES
  * `cp .config $(dirname $(which ix))/pkgs/bin/kernel/configs/cfg_6_14`
  `ix mut system bin/kernel/6/15`
* Setup [Grub](https://stal-ix.github.io/GRUB.html)
  * `ix mut bin/grub/bios`
  * From a user with sudo privileges:
    * `sudo /mnt/ix/usr/sbin/grub-install --target=i386-pc --boot-directory=/mnt/ix/boot /dev/vdb`
    * `sudo mkdir -p /mnt/ix/boot/grub`
    `echo 'configfile /etc/grub.cfg' | sudo tee /mnt/ix/boot/grub/grub.cfg`
  * `ix mut system bin/kernel/gengrub`
* Reboot, choosing vdb as our boot disk
* It boots, but mysteriously stalls after remounting the boot disk read/write
  * Nothing happens on any VT after that
  * The system [keeps no logs](https://github.com/stal-ix/stal-ix.github.io/blob/main/CAVEATS.md), so it's hard to figure out what happened
  * Perhaps I missed a kernel config option? But rebuilding the kernel rebuilds of all of LLVM each time I try, so it takes too long to try too many times
  * I can boot with init=/bin/sh and get a shell. But even after mounting all the right filesystems, I wasn't able to rescue
