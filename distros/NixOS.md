# NixOS

## Bootstrapping info

Upstream: https://nixos.org/

Bootstrapping documentation:

* [Installing Nix from source](https://nix.dev/manual/nix/2.28/installation/installing-source.html)
* [Building a bootable ISO](https://nix.dev/tutorials/nixos/building-bootable-iso-image.html)
* [Installing NixOS from another distro](https://nixos.org/manual/nixos/stable/index.html#sec-installing-from-other-distro)

Requirements: POSIX, with many supporting libraries

Automation: Mostly automated, some intervention needed due to broken sources

Integration testing: No

What you get: A package manager. But I've not been able to build a bootable OS.

Can install further software from source: Yes

Why it doesn't count: Fails to build an ISO or install tools, remains just a secondary package manager

## Manual testing

Version: NixOS 25.05, Nix 2.28.4

Architecture: x86_64

Date: 2025-07-08

Build time:

* 25 minutes to a Nix binary, on i5-10310U
* 3 hours to bootstrap Nix
* At least 6 hours to a bootable system, but it didn't complete

### Testing process

* Using Arch Linux host, building in a Debian 12 VM
* Dependencies
  * Most prerequisites are from [the instructions](https://nix.dev/manual/nix/2.28/installation/prerequisites-source), but many were implicit and needed to be figure out
  * `sudo apt install autoconf automake gcc g++ pkg-config libssl-dev libbrotli-dev libcurl4-openssl-dev libsqlite3-dev libsodium-dev bison flex libcpuid-dev git wget cmake libarchive-dev nlohmann-json3-dev libtoml11-dev libreadline-dev curl libbz2-dev libdbd-sqlite3-perl libperl-dev gperf`
  * Install newer meson
    * Add Debian backports: https://backports.debian.org/Instructions/
    `sudo apt install -t bookworm-backports meson`
  * Install newer libseccomp
    * `cd ~`
    * `wget https://github.com/seccomp/libseccomp/releases/download/v2.6.0/libseccomp-2.6.0.tar.gz`
    * `tar xf libseccomp-2.6.0.tar.gz`
    * `cd libseccomp-2.6.0`
    * `./configure`
    * `make -j8`
    * `sudo make install`
  * Install newer boost
    * `cd ~`
    * `wget https://archives.boost.io/release/1.88.0/source/boost_1_88_0.tar.gz`
    * `tar xf boost_1_88_0.tar.gz`
    * `cd boost_1_88_0`
    * `./bootstrap.sh`
    * `./b2 -j8`
    * `sudo ./b2 install --prefix=/usr/local`
  * Install newer gtest
    * `cd ~`
    * `wget -O googletest-1.17.0.tar.gz https://github.com/google/googletest/releases/download/v1.17.0/googletest-1.17.0.tar.gz`
    * `tar xf googletest-1.17.0.tar.gz`
    * `cd googletest-1.17.0`
    * `cmake .`
    * `make -j8`
    * `sudo make install`
  * Install libblake3
    * `cd ~`
    * `wget -O blake3-1.8.2.tar.gz https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/1.8.2.tar.gz`
    * `tar xf blake3-1.8.2.tar.gz`
    * `cd BLAKE3-1.8.2/c`
    * `cmake .`
    * `make -j8`
    * `sudo make install`
  * Install rapidcheck, including pkgconfig and gtest
    * `cd ~`
    * `git clone https://github.com/emil-e/rapidcheck.git`
    * `cd rapidcheck`
    * `cmake -DRC_ENABLE_GTEST=ON -DBUILD_SHARED_LIBS=ON .`
    * `make -j8`
    * `sudo make install`
  * Install newer libgit2
    * `cd ~`
    * `wget -O libgit2-1.9.1.tar.gz https://github.com/libgit2/libgit2/archive/refs/tags/v1.9.1.tar.gz`
    * `tar xf libgit2-1.9.1.tar.gz`
    * `cd libgit2-1.9.1`
    * `cmake .`
    * `make -j8`
    * `sudo make install`
  * Install newer boehm-gc (see [this issue](https://github.com/NixOS/nix/issues/10147)0
    * `cd ~`
    * `wget https://www.hboehm.info/gc/gc_source/gc-8.2.8.tar.gz`
    * `tar xf gc-8.2.8.tar.gz`
    * `cd gc-8.2.8`
    * `cmake -Denable_cplusplus=ON .`
    * `make -j8`
    * `sudo make install`
* Get Nix source
  * We want a version that's [stable in NixOS](https://nix.dev/reference/nix-manual). That's be 2.28.4, stable in NixOS 25.05.
  * `git clone https://github.com/NixOS/nix -b 2.28.4 ~/nix-src`
* Build Nix
  * `cd ~/nix-src`
  * `meson setup -Dprefix=$HOME/nix -Dlocalstatedir=$HOME/nix/var -Dsysconfdir=$HOME/nix/etc -Dlibcmd:readline-flavor=readline -Dlibstore:log-dir=$HOME/nix/var/log -Dlibstore:store-dir=$HOME/nix-store build`
    * Using a different store-dir ensures we don't download cached binaries
    * Nix really seems to expect users to use cached binaries
  * `meson compile -C build`
  * `meson install -C build`
* Setup nix environment
  * Ensure we can find Nix libraries. This may not be necessary
    * `echo $HOME/nix/lib/x86_64-linux-gnu | sudo tee /etc/ld.so.conf.d/nix.conf`
    * `sudo ldconfig`
  * `mkdir -p ~/nix/var/nix`
  * `export PATH="$HOME/nix/bin:$PATH"`
  * `. ~/nix/etc/profile.d/nix.sh`
  * `nix-channel --add https://nixos.org/channels/nixos-25.05 nixpkgs`
  * `nix-channel --update`
  * Create ~/nix/etc/nix/nix.conf:

        hashed-mirrors = https://tarballs.nixos.org/

* Make sure we can bootstrap, by building an innocuous package
  * `nix-build '<nixpkgs>' -A less -v`
  * This uses a [small set of binary bootstrap tools](https://trofi.github.io/posts/240-nixpkgs-bootstrap-intro.html)
    * This is not ideal! These are distro-specific built tools, which could go away irretrievably, or be subverted. But it's a very early bootstrap stage, so I'll accept it.
    * There's [incomplete work on a full bootstrap](https://github.com/NixOS/nixpkgs/issues/123095)
  * Deal with broken savannah git
    * `nix-prefetch-url 'https://gitlab.com/freedesktop-sdk/mirrors/savannah/config/-/raw/948ae97ca5703224bd3eada06b7a69f40dd15a02/config.sub' --name config.sub-948ae97`
    * `nix-prefetch-url 'https://gitlab.com/freedesktop-sdk/mirrors/savannah/config/-/raw/948ae97ca5703224bd3eada06b7a69f40dd15a02/config.guess' --name config.guess-948ae97`
  * Some packages may complain about scripts not being able to run, due to missing files:
    * Fix with `sudo apt install busybox-static`
  * Some packages print errors running busybox commands:
    * Just build them with `--option sandbox false`. Consider even setting this in nix.conf
* Build an ISO
  * We'll use a clone of nixpkgs, so we can fix any breakages that arise. It's not uncommon for packages to have broken source
    * `git clone --depth=1 -b nixos-25.05 https://github.com/NixOS/nixpkgs.git ~/nixpkgs`
    * `cd ~/nixpkgs`
  * Increase open file limit: `ulimit -n 8192`
  * `nix-build nixos/release.nix -A 'iso_minimal.x86_64-linux' -v`
    * Lots of broken URLs to find other sources for
    * Many savannah git sources are used, but that site is often down. Some repos seem to have no mirror at all! Need to delay build until git.savannah is up again
    * ghc-binary packages are fetched, but it looks like just for bootstrapping purposes. Looks like this we only really need GHC for ShellCheck, that's a big dep graph pulled in for one test tool.
    * Somehow squashfs-tools has a hash mismatch for the sources. Hard to debug when it's a recursive hash.
      * Just update the hash in squashfsTools/package.nix
  * Errors trying to build nix, mostly in nix-store-tests. I don't really understand what's going wrong, or how to fix it
* Similarly, trying to build install-tools fails: `nix-env -f '<nixpkgs>' -iA nixos-install-tools`
