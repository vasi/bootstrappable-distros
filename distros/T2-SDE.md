# T2 SDE

## Bootstrapping info

Upstream: https://t2sde.org/

Bootstrapping documentation: https://t2sde.org/handbook/html/t2-book.html#t2.build

Requirements: Linux with compilers and a variety of packages

Automation: Yes, the t2 script automates almost everything (that doesn't fail)

Integration testing: No

What you get: A basic command-line system

Can install further software from source: Yes, with t2 on the target

## Manual testing

Version: 25.4, SVN revision r76104

Architecture: x86_64

Date: 2025-07-03

Build time: 15 hours on i5-10310U

### Testing process

* Using Arch Linux host, but just to run VMs
  * We'll need to use a VM instead of containers, since T2 wants to be able to mount things as part of the build
  * Building in Debian 12 VM
* Install dependencies
  * `sudo apt install subversion gcc libncurses-dev make gawk curl file bzip2 xz-utils lzip flex patch bison texinfo time rsync python3 psmisc g++ libgmp-dev libmpfr-dev libmpc-dev cmake binutils-dev pkg-config scdoc libzstd-dev pipx libssl-dev gperf liblzma-dev dosfstools mtools squashfs-tools xorriso`
  * Needs a recent meson, so install with pipx
    * `pipx install meson`
    * `pipx ensurepath`, then restart the shell
  * Add /usr/sbin to PATH
* Get source
  * There aren't really source snapshots anymore, gotta fetch from SVN
  * `svn co https://svn.exactcode.de/t2/tags/25.4 t2-sde`
  * `cd t2-sde`
* Switch to root, T2 insists on it:`sudo --preserve-env=PATH -s`
* Configure T2: `./t2 config`
  * Choices
    * Base package selection: base
    * System type: Install iso
    * Do not continue on package errors
    * Do not try building packages if deps failed
    * Don't use tmpfs for building
    * Enable expert options, and custom package selection
  * Set the custom package selection to deal with missing dependencies. Create `config/default/pkgsel`

        X perl
        X python
        X meson
        X python-gpep517
        X setuptools
        X python-installer
        X ninja
        X gperf
        X jinja2
        X python-flit-core
        X markupsafe
        X scons
        O thin-provisioning-tools

    * Re-rerun `./t2 config` then exit, to regenerate after the package selections
* Fix several different packages whose build would otherwise break
  * Most of my fixes are in [this patch](../data/t2.patch). Apply it.
* Download sources: `./t2 download -required`
  * Manually download anything that fails to download, into a subfolder of "download/mirror"
* Build: `./t2 build-target`
  * There's still a couple of package failures I'm not sure how to fix in source, but we can deal with them manually
  * grub2 will fail because there's a strip-wrapper that wraps nothing
    * When this happens, remove the wrapper: `rm build/default-25.4-generic-x86-64-linux/TOOLCHAIN/tools.chroot/wrapper/x86_64-t2-linux-gnu-strip`. Then restart the build
  * The t2-src will fail. When this happens, just restart the build, and it appears to succeed
* Create ISO: `./t2 create-iso default`
  * This builds "default.iso"
* Boot the ISO in a new VM
  * The ISO environment is slightly broken, eg: libpcre is missing so grep doesn't work. But it's good enough
  * Run `install` to enter the installer
  * Choose "classic partitioning"
    * The installer has trouble understanding that partitions are mounted, just tell it to continue when you're sure they're mounted
  * The gasgui packager has some trouble
    * Quit the installed, and manually mount /dev/sr0 to /media
    * Run `gasgui -s /media -t /mnt -c 25.4-generic-x86-64-linux -S tar.zst`
    * Install defaults, then re-run installer
  * Continue with installer straightforwardly
* Reboot into the installation
  * Hostname didn't get set properly, edit /etc/hostname
  * Enable root login via SSH
  * We're supposed to have t2 source in /usr/src/t2-src, but that job failed and it looks like it didn't retry properly
    * Just re-checkout with svn: `svn co https://svn.exactcode.de/t2/tags/25.4 /usr/src/t2-src`
* Build a package
  * `cd /usr/src/t2-src`
  * `./t2 install nano`
