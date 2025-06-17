# Void Linux

## Bootstrapping info

Upstream: https://voidlinux.org/

Bootstrapping documentation: https://github.com/void-linux/void-packages?tab=readme-ov-file#install-the-bootstrap-packages

Requirements: Linux with a compiler and common tools

Automation: Minimal

Integration testing: No

What you get: Unknown, it doesn't work

Can install further software from source: Probably, with xbps-src

Why it doesn't count: Bootstrapping completely fails

## Manual testing

Version: void-packages git commit cf623fe1

Architecture: amd64

Date: 2025-06-16

Build time: Incomplete

### Testing process

* Using Arch Linux host. But this is just to host a VM, you could run this anywhere.
  * Void doesn't easily bootstrap in a container, since it wants to use chroot-ish tools. So we need to do it in a VM
* Run a minimal Debian 12 VM. All following steps occur in the VM
* Setup dependencies
  * `apt update`
  * `apt full-upgrade`
  * `apt install git gcc make pkgconf zlib1g-dev libssl-dev libarchive-dev sudo nano file gawk g++ gnat libarchive-tools curl python3 texinfo bison`
* Create a user
  * `useradd -m void -G sudo -s /bin/bash`
  * `visudo` and change the line starting with '%sudo' to work without a password: `%sudo   ALL=(ALL:ALL) NOPASSWD: ALL`
  * `passwd void` to set the password
  * Login as the user
* Install xbps
  * `git clone https://github.com/void-linux/xbps.git`
  * `cd /xbps`
  * `./configure --prefix=/usr`
  * `make -j8`
  * `sudo make install`
* Setup void-packages repo
  * `cd`
  * `git clone --depth=1 https://github.com/void-linux/void-packages.git`
  * `cd ~/void-packages`
* Bootstrap stage0
  * `./xbps-src bootstrap`
  * Fails due to tar not being a "bootstrap package". Add bootstrap=yes to tar template
  * acl package fails to configure, thinks C compiler doesn't build
    * Maybe due to some environment variable? It's hard to figure out to debug
    * I can't find any way to handle these problems incrementally, each attempt forces a rebuild from the start
    * Docs seem to indicate that bootstrapping is fragile and often breaks
    * Giving up!
