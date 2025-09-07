# Azure Linux

## Bootstrapping info

Upstream: https://github.com/microsoft/AzureLinux

Bootstrapping documentation: https://gist.github.com/Googulator/2eea4b46b2e9139b624665d23e3578da

Requirements: git python3

Automation: Mostly manual

Integration testing: None

What you get: TODO

Can install further software from source: TODO

Why it doesn't count: Can't repr oduce the bootstrap yet, but I'll keep working to understand the problem TODO

## Manual testing

TODO: commits of azurelinux, gist
Version: 3.0, git commit 4e95ed11 on Googulator's 3.0-bootstrap branch

Architecture: x86_64

Date: 2025-09-01

Build time: ~9h on i7-9750H, until failure

TODO
6h to live-bootstrap
5h to toolchain
8h first run of ISO

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
    * Resize the disk, 300 GB is reasonable
    * Make sure the VM has e1000 network, and SATA disk, so boot scripts keep working
    * This is also a good time to backup!
* Start the live-bootstrap VM
  * For most upcoming build steps, I won't share the full commands, but just reference steps from [the docs](https://gist.github.com/Googulator/2eea4b46b2e9139b624665d23e3578da), and any changes I had to make
  * Setup SSH
    * Setup devpts, shells, environment
    * Build dropbear, scp/sftp
    * Set a password, and start dropbear
  * SSH in! We can now run commands more easily
  * Setup environment
  * Build git, cmake, attr, acl, libcap, bzlib, cdrkit, jq, zstd, pixz, wget, rsync, util-linux, parted, lua, popt, tcl, sqlite, rpm, musl-cross-make, pcre, pcre2, grep, nina, meson, glib, qemu, dosfstools, autoconf-dickey, ncurses
  * For ease of debugging, consider also installing things like less, psmisc, procps, btop, nano
  * Build the 64-bit kernel
    * First, copy kconfig64 to /root
  * Build go 1.4, 1.17, 1.20, 1.
  * Configure LFS user, runuser, host resolution
  * Bootstrap azurelinux
    * Clone and setup
    * Build go-tools
    * Build toolchain
    * Build ISO
      * Set CONCURRENT_PACKAGE_BUILDS= to lower than the core count, to prevent swapping
      * `sudo make iso CONFIG_FILE="./imageconfigs/full.json" PACKAGE_URL_LIST="" REPO_LIST="" DISABLE_UPSTREAM_REPOS=y REBUILD_TOOLCHAIN=y REBUILD_PACKAGES=y REBUILD_TOOLS=y NO_TOOLCHAIN_CONTAINER=y PACKAGE_BUILD_TIMEOUT=24h  USE_CCACHE=y CONCURRENT_PACKAGE_BUILDS=6`

iso partial: Sep 5 16:22 - 17:55
rebuild: 19:30
TODO

cd /root/azurelinux/build/logs/pkggen/rpmbuilding; find -name '*.log' -printf '%T+ %p\n' | sort | tail -1 | perl -pe 's/^\S*\s//' | while read f; do echo $f; tail -f $f; done

find -name '*.log' -mmin -30 | xargs grep -L 'msg="Built' | xargs  stat -c '%w   %n' | sort -r

grep 'ERRO\[' /root/azurelinux/build/logs/pkggen/workplan/build-rpms.flag.log 