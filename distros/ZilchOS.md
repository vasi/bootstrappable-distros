# ZilchOS

## Bootstrapping info

Upstream: https://github.com/ZilchOS/core

Bootstrapping documentation: https://github.com/ZilchOS/bootstrap-from-tcc

Requirements: Linux with tcc

Automation: Fully automated

Integration testing: No

What you get: A very basic command-line system

Can install further software from source: No

Why it doesn't count: No devtools or packaging

## Manual testing

Version: Git commit d2f9454 of bootstrap-from-tcc

Architecture: x86_64

Date: 2025-07-08

Build time: 12 hours with i7-9750H

### Testing process

* Using Fedora 42 host. Building in Debian 12 VM
* `sudo apt install git make wget bzip2 gcc`
* Download sources
  * `git clone https://github.com/ZilchOS/bootstrap-from-tcc.git ~/bootstrap-from-tcc`
  * `cd ~/bootstrap-from-tcc`
  * Fix URLs, find new sources
    * ftp.gnu.org seems down, change to a mirror
    * Boost URL is dead
  `./download.sh`
* Build static tcc seed
  * `cd ~`
  * `tar xf bootstrap-from-tcc/downloads/tinycc-mob-af1abf1.tar.gz`
  * `make tcc LDFLAGS="-static" -j8`
  * `cp tcc ../bootstrap-from-tcc/tcc-seed`
* Build
  `cd ~/bootstrap-from-tcc`
  * Make sure chroot is accessible: `export PATH="$PATH:/usr/sbin"`
  * `make all-pkgs all-tests iso -j2 NPROC=$(nproc) USE_CCACHE=1 USE_NIX_CACHE=1`
    * Builds a 14 MB ZilchOS-core.iso
  * Hashes don't match, if we try `make verify-all-pkgs-checksums`
* Boot in KVM
  * Boots up fine!
  * There's a nix binary, which at least executes
  * We can't easily "nix build" the ISO again, cuz our checksums don't match
  * No packages available to install
  * There's not even "make" installed, so we can't rebootstrap from scratch
