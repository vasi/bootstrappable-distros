# oasis linux

## Bootstrapping info

Upstream: https://github.com/oasislinux/oasis

Bootstrapping documentation: https://github.com/oasislinux/oasis/wiki/Install

Requirements: Linux with C compiler, Lua, musl-cross-make

Automation: Some automation, many manual steps

Integration testing: [At sourcehut](https://builds.sr.ht/~mcf/oasis), though only part of the bootstrap is tested

What you get: A small command-line system, or a tiny graphical environment

Can install further software from source: Highly restricted package set

## Manual testing

Version: Git commit 160dac1

Architecture: x86_64

Date: 2025-06-28

Build time: 5 hours with i5-10310U

### Testing process

* Using Fedora 42 host, but just to run a VM
  * Build instructions use Debian packages, so use a Debian 12 VM
  * Add a new disk to VM, to store oasis partitions
  * All steps take place in VM until otherwise mentioned
* Dependencies
  * `sudo apt install bison curl git ninja-build lua5.2 pax libwayland-dev libpng-dev nasm make wget xz-utils bzip2 gcc g++ parted rsync flex libelf-dev bc extlinux arch-install-scripts`
* [Build a toolchain with musl-cross-make](https://github.com/richfelker/musl-cross-make)
  * Use [zv's fork](https://git.zv.io/toolchains/musl-cross-make): `git clone https://git.zv.io/toolchains/musl-cross-make.git -b musl.cc-old ~/musl-cross-make`
  * `cd ~/musl-cross-make`
  * Use config from [musl.cc](https://musl.cc):
    * `curl -o config.mak https://conf.musl.cc/plain_20211122_11-2-1.txt`
    * `echo 'TARGET = x86_64-linux-musl' >> config.mak`
  * Deal with broken mirrors
    * `(mkdir -p sources; cd sources; curl -LO https://bigsearcher.com/mirrors/gcc/snapshots/11-20211120/gcc-11-20211120.tar.xz)`
    * `curl -Lo sources/config.sub https://gitlab.com/freedesktop-sdk/mirrors/savannah/config/-/raw/888c8e3d5f7bf7464bba83aaf54304a956eefa60/config.sub`
  * `make -j12`
  * `make install`
  * `export PATH="$PATH:$HOME/musl-cross-make/output/bin"`
* Configure git
  * `git config --global user.name 'Some Name'`
  * `git config --global user.email my@email.com`
* Setup disk, assuming it's /dev/vdb
  * `sudo parted /dev/vdb`
  * In parted:
    * `mklabel msdos`
    * `mkpart primary ext2 1m 300m`
    * `mkpart primary ext4 300m 100%`
    * `set 1 boot on`
  * `sudo mkfs.ext2 /dev/vdb1`
  * `sudo mkfs.ext4 /dev/vdb2`
  * `sudo mount /dev/vdb2 /mnt`
  * `sudo mkdir -p /mnt/boot`
  * `sudo mount /dev/vdb1 /mnt/boot`
  * `sudo chown -R $USER /mnt`
* Build root
  * `export PATH="$PATH:/usr/sbin"`
  * `git clone -c 'core.sharedRepository=group' https://github.com/oasislinux/oasis.git src/oasis`
  * Switch to the last working commit: `git -C src/oasis checkout -b lastok 160dac1`
  * `git init --template src/oasis/template`
  * `cd src/oasis`
  * `cp config.def.lua config.lua`
  * `nano config.lua`
    * Put the following on the line after "local sets = ...":

          local all = {}
          for _, ps in pairs(sets) do
                  table.insert(all, ps)
          end

    * Make sure the repo settings look like:

          repo={
            path='../..',
            flags='',
            tag='tree',
            branch='oasis',
          }

    * The fs setting setting should ideally just be `fs=all,`. But some fail mysteriously, so let's do `fs={sets.core, sets.devel, sets.extra},`.

  * `lua setup.lua`
  * Fix some URLs: `perl -i -pe 's,//[^/]+/,//openbsd.cs.toronto.edu/,' pkg/openbsd/url`
  * `ninja commit`
  * `cd /mnt`
  * `git config branch.master.remote .`
  * `git config branch.master.merge oasis`
  * `git merge`
  * `./libexec/applyperms`
* Setup /etc
  * `(cd /tmp && curl -LO https://github.com/oasislinux/etc/archive/master.tar.gz)`
  * `zcat /tmp/master.tar.gz | pax -r -s ',^etc-[^/]*,etc,'`
  * `./libexec/applyperms -d etc`
  * `rm etc/.perms`
  * `ln -s ../share/zoneinfo/America/Toronto etc/localtime`
  * Setup fstab. We'll use `vda` here because we'll be booting oasis standalone, without the Debian disk.

        cat >>etc/fstab <<EOF
        /dev/vda2 / ext4 rw,relatime 0 1
        /dev/vda1 /boot ext2 rw,relatime,noauto 0 0
        EOF

  * `touch /var/log/lastlog`
  * `sudo arch-chroot /mnt /bin/sh`, then `passwd` to set a password, then exit
* Build a kernel, using the [provided configs](https://github.com/oasislinux/linux-configs)
  * `cd`
  * `curl -LO https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.0.10.tar.xz`
  * `curl -L -o kernel-config-qemu https://raw.githubusercontent.com/oasislinux/linux-configs/refs/heads/master/qemu`
  * `tar xf linux-6.0.10.tar.xz`
  * `cd linux-6.0.10`
  * `./scripts/kconfig/merge_config.sh -n ~/kernel-config-qemu`
  * `make -j12`
  * `cp arch/x86/boot/bzImage /mnt/boot/linux`
* Install a bootloader
  * `mkdir /mnt/boot/syslinux`
  * `sudo extlinux --install /mnt/boot/syslinux`
  * `sudo dd if=/usr/lib/EXTLINUX/mbr.bin of=/dev/vdb bs=440`

        cat >$ROOT/boot/syslinux/syslinux.cfg <<EOF
        PROMPT 1
        TIMEOUT 10
        DEFAULT oasis

        LABEL oasis
          LINUX ../linux
          APPEND root=/dev/vda2 init=/bin/sinit ro
        EOF
* Put our toolchain in /mnt in preparation for building a real oasis toolchain: `tar --zstd -cvf /mnt/cross-tools.tar.zst -C ~/musl-cross-make/output .`
* Boot with qemu: `qemu-system-x86_64 -accel kvm -m 30g -smp 12 -drive file=oasis.qcow2,if=virtio -device virtio-keyboard -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2222-:22`
  * Login as root
  * [Setup DHCP](https://github.com/oasislinux/oasis/wiki/Administration#enable-dhcp-on-eth0). Use "vis" as an editor.
  * [Setup SSH](https://github.com/oasislinux/oasis/wiki/Administration#enabling-sshd), and permit root login
    * Need to `chown root /var/empty /root`
* Try to [setup a native toolchain](https://github.com/oasislinux/oasis/wiki/Toolchain)
  * Unpack our cross-tools:
    * `mkdir /crosstools`
    * `zstd -cd /cross-tools.tar.zst | tar -x -C /crosstools`
  *  Make the tools findable:
    * `cd /crosstools/bin`
    * `for i in x86_64-linux-musl-*; do ln -s $i ${i##x86_64-linux-musl-}; done`
    * `export PATH="$PWD:$PATH"`
    * Also make some libraries usable for the build: `export LD_LIBRARY_PATH=/crosstools/x86_64-linux-musl/lib`
  * Fetch a new musl-cross-make
    * `git clone https://github.com/oasislinux/musl-cross-make /src/musl-cross-make`
    * `cd /src/musl-cross-make`
  * Use the [config.mak from oasis](https://github.com/oasislinux/oasis/wiki/Toolchain#configure)
  * Fetch config.sub manually, as above
  * `make -j12`
  * Setup as [externally built software](https://github.com/oasislinux/oasis/wiki/Repository#managing-externally-built-software)
    * `git -C / worktree add --detach --no-checkout $PWD/output-x86_64-linux-musl`
    * `git -C output-x86_64-linux-musl symbolic-ref HEAD refs/heads/toolchain`
    * `make install`
    * `ln -s gcc output-x86_64-linux-musl/cc`
    * `git -C output-x86_64-linux-musl add .`
    * `git -C output-x86_64-linux-musl commit -m musl-cross-make`
    * `git -C / config --add branch.master.merge toolchain`
    * `git -C / merge --allow-unrelated`
    * Fix merge conflict:
      * `git -C / checkout --ours /`
      * `git -C / commit -a`
    * Remove /crosstools
* Package installation with oasis tools
  * Add a package to "fs" in /src/oasis/config.lua , eg: `{"catgirl"}`
  * `lua setup.lua`
  * `samu commit`
  * `git -C / merge`
  * There's not many packages available here, just 150
* The distro [recommends pkgsrc](https://github.com/oasislinux/oasis/wiki/pkgsrc), let's try that
  * Setup
    * `git clone -c 'core.sharedRepository=group' https://github.com/oasislinux/pkgsrc.git /src/pkgsrc`

          cat >/root/pkgsrc.mk <<'EOF
          MACHINE_GNU_PLATFORM=x86_64-linux-musl
          BUILDLINK_TRANSFORM+=rm:-lbsd
          COMPILER_INCLUDE_DIRS=/include
          LIBABISUFFIX=
          ROOT_CMD=doas sh -c
          TOOLS_PLATFORM.bash=
          TOOLS_PLATFORM.lex=/bin/lex
          TOOLS_PLATFORM.flex=/bin/flex
          TOOLS_PLATFORM.gm4=
          TOOLS_PLATFORM.gsed=
          TOOLS_PLATFORM.m4=/bin/m4
          TOOLS_PLATFORM.ninja=/bin/samu
          TOOLS_PLATFORM.patch=/bin/patch
          TOOLS_PLATFORM.pax=/bin/pax
          TOOLS_PLATFORM.sed=/bin/sed
          TOUCH_FLAGS=
          EOF

    * `cd /src/pkgsrc`
    * `env groupsprog='id -Gn' FGREP='/bin/grep -F' EGREP='/bin/grep -E' TOUCH_FLAGS= ./bootstrap/bootstrap --prefix /pkg --prefer-pkgsrc yes --mk-fragment /root/pkgsrc.mk`
    * Edit ~/.profile to add /pkg/bin:/pkg/sbin to PATH
    * Consider adding MAKE_JOBS to /pkg/etc/mk.conf
    * I suppose we could try to manage this with git, like other "external software"? But pkgsrc wants to be installed to a place it can run from, so merging wouldn't work
  * Try installing something, eg: nano
    * `cd /src/pkgsrc/editors/nano`
    * `bmake install`
    * We first get errors on ncurses, about linking libstdc++.a into dynamic libraries, which predictably fails. Add `LDFLAGS += -static` to mk.conf
    * We then get errors about linking non-PIE libstdc++.a, but that's weird if we're building statically. Even if I add `--with-normal` to ncurses to make it build statically, this still happens when building the "demo" app.
    * Not sure how to fix this
