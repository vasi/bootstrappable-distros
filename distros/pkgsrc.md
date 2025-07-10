# pkgsrc

## Bootstrapping info

Upstream: https://www.pkgsrc.org/

Bootstrapping documentation: https://www.netbsd.org/docs/pkgsrc/platforms.html#bootstrapping-pkgsrc

Requirements: POSIX with a compiler

Automation: Some automation, but uses system toolchain

Integration testing: No

What you get: A secondary package manager

Can install further software from source: Yes

Why it doesn't count: Not a bootable OS, just a secondary package manager

## Manual testing

Version: "current" as of 2025-07-10

Architecture: x86_64

Date: 2025-07-10

Build time: 3 hours on i5-10310U to get a toolchain built

### Testing process

* Using Arch Linux host, building in a Debian 12 VM
* Install dependencies: `sudo apt install wget xz-utils gcc g++ file`
* Install pkgsrc:
  * `cd ~`
  * `wget https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.xz`
  * `tar -xf pkgsrc.tar.xz`
  * `cd pkgsrc/bootstrap`
  * `./bootstrap --prefix $HOME/pkg --prefer-pkgsrc yes --make-jobs 8 --unprivileged`
  * `export PATH="$HOME/pkg/bin:$HOME/pkg/sbin:$PATH"`
  * Edit ~/pkg/etc/mk.conf, add "MAKE_JOBS=8"
* Make sure we can build a package
  * `cd ~/pkgsrc/achivers/pixz`
  * `bmake install`
* Build a non-system toolchain
  * Build each of: devel/binutils lang/gcc14 net/wget archivers/xz sysutils/file
    * For each package, cd to the directory, then `bmake install`
    * binutils fails with an unimport PLIST mismatch. Fix:
      * `bmake print-PLIST > PLIST.new`
      * Edit Makefile so `PLIST_SRC=PLIST.new`. Comment out any other PLIST_SRC lines
      * Then `bmake install` to contine
  * Configure toolchain
    * Put the new tools in path: `export PATH="$HOME/pkg/gcc14/bin:$HOME/pkg/x86_64-debian-linux/bin:$PATH"`
    * Add to mk.conf: "TOOLS_PLATFORM.gstrip?=$(HOME)/pkg/bin/gstrip"
  * Uninstall system packages, except libc6-dev
  * Try installing another tool with pkgsrc, eg: ncdu. It works!
* No way to make this bootable. Aside from installing [NetBSD](NetBSD.md)!
