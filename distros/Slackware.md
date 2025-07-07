# Slackware

## Bootstrapping info

Upstream: http://www.slackware.com/

Bootstrapping documentation: https://github.com/nobodino/slackware-from-scratch/blob/master/documentation/howto-SFS

Requirements: Unspecified

Automation: Some, but many manual steps

Integration testing: No

What you get: Unclear, incomplete

Can install further software from source: Probably with SlackBuild?

Why it doesn't count: Downloads binary packages

## Manual testing

Version: 14.1?

Architecture: x86_64

Date: 2025-07-06

Build time: Incomplete

### Testing process

* Using Arch Linux host. But it's just to run VMs
  * Build process wants an extra attached disk, so we'll use a VM
  * Start a Debian 12 VM, with an extra disk attached
* Login as root
* Dependencies: `apt install parted git wget rsync lftp xz-utils`
* Setup disk
  * Partition disk /dev/sda. Use MBR, with a single giant ext4 partition, marked bootable
  * `mkfs.ext4 /dev/sda1`
  * `mount /dev/sda1 /mnt/sfs`
  * `export SFS=/mnt/sfs`
* Get source
  * `mkdir -pv $SFS/tools`
  * `git clone https://github.com/nobodino/slackware-from-scratch.git $SFS/scripts`
    * This seems to include a variety of binaries!
      * "packages_for_aaa_libraries" is full of binary packages
      * "musl/others/installer" contains a prebuild initrd.img
  * `cd $SFS/scripts`
  * `chmod +x *`
* Configure source
  * Edit myprofile
    * fstab section
      * Remove swap
      * Remove floppy
      * Use sda1 as root
    * Set timezone, language, keymap
    * Use 1.1.1.1 nameserver
  * `cp variables_perso/export_variables_perso .`
  * `export PATDIR=/mnt/ext4/sda4/sfs`
  * `mkdir -p $PATDIR/{tools,tools_dev,tools_64,tools_64_dev,others}`
  * Edit export_variables, choose an [rsync mirror](https://mirrors.slackware.com/mirrorlist/)
* Bootstrap
  * `./sfs-bootstrap`
    * Choose: slackware, x86_64, current, rsync, upgrade
  * This downloads mostly source, but also [a variety of binary packages](https://github.com/nobodino/slackware-from-scratch/blob/master/sfs-bootstrap#L402-L443)!
  * We're dropped in a chroot
* Run the build
  * `cd /mnt/sfs/scripts  && source ~/.bash_profile`
  * `./sfs-tools`
  * We're told the script can't find a binutils-2.44.tar.?z file
  * Quitting here, since we've made very little progress, and downloaded lots of binary packages
