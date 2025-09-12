# Azure Linux

## Bootstrapping info

Upstream: https://github.com/microsoft/AzureLinux

Bootstrapping documentation: https://gist.github.com/Googulator/2eea4b46b2e9139b624665d23e3578da

Requirements: git python3

Automation: Mostly manual

Integration testing: None

What you get: A command line Linux

Can install further software from source: Yes, by re-bootstrapping

## Manual testing

Version: 
* [Commit 6a8b54d4](https://github.com/Googulator/azurelinux/tree/6a8b54d4e365e99320b499712dba0c94de480777) on the 3.0-bootstrap branch of Azure Linux
* [Commit cbe69123](https://gist.github.com/Googulator/2eea4b46b2e9139b624665d23e3578da/cbe6912334ebf56679514d15100d293d0153ed9f) of the bootstrap-azurelinux.sh gist

Architecture: x86_64

Date: 2025-09-09

Build time:
* About 2 days to build and install, on i7-9750H
* Another few hours to build packages from source

### Testing process

* Using Fedora 42 host, doing most work in VMs
* First we'll configure and kick off live-bootstrap on the host
  * Install dependencies: `dnf install git python3 python3-requests curl xz`
  * Clone a branch of live-bootstrap: https://github.com/fosslinux/live-bootstrap/pull/469
    * `git clone https://github.com/fosslinux/live-bootstrap.git`
    * `cd live-bootstrap`
    * `git fetch origin pull/469/head:azurelinux`
    * `git switch azurelinux`
    * `git submodule update --init --recursive`
  * Make a local mirror: `mkdir mirror; ./mirror.sh mirror`
  * Kick off qemu mode: `./rootfs.py --arch x86 -t azurelinux --cores $(nproc) --update-checksums --interactive --mirror file://$PWD/mirror --qemu --qemu-ram=16384`
* live-bootstrap continues in a qemu VM for several hours
  * Afterwards, we're left at a prompt
  * Safely shut down: `sync; sync; echo u > /proc/sysrq-trigger; echo o > /proc/sysrq-trigger`
  * On the host, turn azurelinux/init.img into a libvirt VM, so I can more easily adjust RAM, networking, etc
    * Resize the disk, 400 GB is reasonable
    * Make sure the VM has e1000 network, and SATA disk, so boot scripts keep working
    * This is also a good time to backup!
* Start the live-bootstrap VM
  * For most upcoming build steps, I won't share the full commands, but just reference steps from [the docs](https://gist.github.com/Googulator/2eea4b46b2e9139b624665d23e3578da), and any changes I had to make
  * Setup SSH
    * Setup devpts, shells, environment
    * Build dropbear, scp/sftp
    * Set a password, and start dropbear
  * SSH in! We can now paste in commands easily
  * Setup environment
  * Build git, cmake, attr, acl, libcap, bzlib, cdrkit, jq, zstd, pigz, wget, rsync, util-linux, parted, lua, popt, tcl, sqlite, rpm, musl-cross-make, pcre, pcre2, grep, ninja, meson, glib, qemu, dosfstools, autoconf-dickey, ncurses
  * For ease of debugging, consider also build helpers like less, psmisc, procps, btop, nano, etc
  * Build the 64-bit kernel
    * First, copy kconfig64 to /root
  * Build go 1.4, 1.17, 1.20, 1.23
  * Configure LFS user, runuser, host resolution
    * Build iproute2
  * Build azurelinux packages and ISO
    * Clone and setup
    * Build go-tools
    * Build toolchain
    * Build ISO
      * [Fix a problem in coredns](https://github.com/Googulator/azurelinux/pull/1)
      * Choose a custom CONCURRENT_PACKAGE_BUILDS= to lower than the core count, to prevent swapping
      * Final command is something like: `sudo make iso CONFIG_FILE="./imageconfigs/full.json" PACKAGE_URL_LIST="" REPO_LIST="" DISABLE_UPSTREAM_REPOS=y REBUILD_TOOLCHAIN=y REBUILD_PACKAGES=y REBUILD_TOOLS=y NO_TOOLCHAIN_CONTAINER=y PACKAGE_BUILD_TIMEOUT=24h  USE_CCACHE=n CONCURRENT_PACKAGE_BUILDS=4`
    * An ISO is created in directory /root/azurelinux/out/images/full
* Install from the ISO in a new target VM
  * Graphical installer doesn't seem to work, but text installer is fine
  * SSH is running on installed system
  * Disable upstream repos so we don't install binaries: `sudo rename .repo .repo.bak /etc/yum.repos.d/*.repo`
* To build new packages:
  * On live-bootstrap VM:
    * Install libgpg-error, libgcrypt, libassuan, libksba, hpth, gpg
    * This is a good point to change the CPU count and memory size of the VM, since we don't need it to be beefy anymore
    * Generate GPG key
    * Find out the IP address with `ip addr show dev eth0`
    Setup a repo of the RPMs we build, and serve it
    * Leave this VM open, so it can be accessed by the target VM
  * On the target VM, as root:
    * Set `IP=<IP address of live-bootstrap-vm>
    * Make sure we can access the live-bootstrap VM: `curl $IP:8000`
    * Configure a yum repo to access the live-bootstrap machine
    * Clone azurelinux
      * Install prerequisites
      * Setup LFS user
    * Install toolchain dependencies with tdnf
    * Build go tools
    * Build toolchain
      * You could plausibly just copy the toolchain from the live-bootstrap VM instead of rebuilding this
    * Build a particular package from source, eg: `sudo make build-packages PACKAGE_URL_LIST="" REPO_LIST="" DISABLE_UPSTREAM_REPOS=y REBUILD_TOOLCHAIN=y REBUILD_PACKAGES=y REBUILD_TOOLS=y NO_TOOLCHAIN_CONTAINER=y PACKAGE_BUILD_TIMEOUT=24h USE_CCACHE=n CONCURRENT_PACKAGE_BUILDS=4 SPECS_DIR=/build/azurelinux/SPECS-EXTENDED SRPM_PACK_LIST="gdisk"`
    * Install the package: `rpm -Uvh ../out/RPMS/x86_64/gdisk-1.0.10-3.azl3.x86_64.rpm`

