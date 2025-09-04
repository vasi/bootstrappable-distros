# Azure Linux

## Bootstrapping info

Upstream: https://github.com/microsoft/AzureLinux

Bootstrapping documentation: https://gist.github.com/Googulator/2eea4b46b2e9139b624665d23e3578da

Requirements: git python3

Automation: Mostly manual

Integration testing: None

What you get: Unclear, broken

Can install further software from source: Unclear, broken

Why it doesn't count: Can't reproduce the bootstrap yet, but I'll keep working to understand the problem

## Manual testing

Version: 3.0, git commit 6a8b54d4 on Googulator's 3.0-bootstrap branch

Architecture: x86_64

Date: 2025-09-01

Build time: ~9h on i7-9750H, until failure

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
  * Kick off qemu mode: `./rootfs.py --arch x86 -t azurelinux --cores $(nproc) --update-checksums --interactive --mirror file://$PWD/mirror --qemu --qemu-ram=16384 --target-size=100g`
* live-bootstrap continues in a qemu VM for several hours
  * Afterwards, we're left at a prompt
  * Safely shut down: `sync; sync; echo u > /proc/sysrq-trigger; echo o > /proc/sysrq-trigger`
  * On the host, turn azurelinux/init.img into a libvirt VM, so I can more easily adjust RAM, networking, etc
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
  * Build git, cmake, attr, acl, libcap, bzlib, cdrkit, jq, zstd, pixz, wget, rsync, util-linux, parted, lua, popt, rpm, musl-cross-make
  * Skip building pcre 1
    * Instead, build and install pcre2 10.46
    * Use `./configure --prefix=/usr --sbindir=/usr/bin --libdir=/usr/lib/i686-unknown-linux-musl --build=i686-unknown-linux-musl --enable-pcre2-16 --enable-pcre2-32 --enable-rebuild-chartables --enable-jit`
  * Skip re-building grep 3.7
    * Instead, download and build grep 3.9 (not listed in build doc) which knows about pcre2
  * Build ninja, meson
  * Build glib
    * Prepend `PKG_CONFIG_PATH=/usr/lib/${TARGET}/pkgconfig/` to the meson setup
  * Build qemu
    * se git URL https://gitlab.com/qemu-project/qemu.git
    * Prepend `PKG_CONFIG_PATH=/usr/lib/${TARGET}/pkgconfig/` to configure
  * Build dosfstools
  * Build a 64-bit kernel
    * Kexec into it: `kexec -f --command-line='root=/dev/sda1 rootwait rw init=/init consoleblank=0' /boot/vmlinuz`
    * Then SSH back in, and setup the environment again
  * Build go1.4
    * Use `CGO_ENABLED=0 GOARCH=386 GOHOSTARCH=386 ./make.bash`
  * Build go1.17, go1.20, go1.23
    * All of these need an added `GOHOSTARCH=386`
  * Build ncurses 6.5-20250830 (not listed in build doc)
    * We'll need this for `tic` in the azurelinux toolchain
    * This needs a custom autoconf
      * Download [dickey's autoconf 2.52-20250126](https://invisible-mirror.net/archives/autoconf/?C=M;O=D)
      * Build with `./configure --prefix=/usr --program-suffix=-dickey` and install
    * Autogen for ncurses with `autoreconf-dickey -v -i -f`
    * Otherwise, configure and build normally
  * Configure LFS user, runuser, host resolution
  * Bootstrap azurelinux
    * When fixing debootstrap.spec, use path `../SPECS/debootstrap/debootstrap.spec`
    * When building go-tools, we keep retrying until we get:

          ../pkg/imagecustomizerlib/imagecustomizer.go:888:16: invalid operation: stat.Frsize * int64(stat.Blocks) (mismatched types int32 and int64)

      Then just give up on fixing it, and continue with the next step.

    * When building the toolchain, we encounter a number of errors, it's inconsistent
      * Can retry, or restart with a `git clean -fxd :/` and then go back to the go-tools stage
      * Some of the errors:
        * In glibc:

              /root/azurelinux/build/toolchain/lfs/tools/lib/gcc/x86_64-lfs-linux-gnu/13.2.0/../../../../x86_64-lfs-linux-gnu/bin/ld: cannot find -lgcc_s: No such file or directory
              collect2: error: ld returned 1 exit status`

        * Or: 

              + mkdir -v build
              mkdir: cannot create directory 'build': File exists
              create_toolchain_in_container.sh failed

        * Or in a sanity check:

              INFO[0000][srpmpacker] Packing SRPMs in the host environment        
              INFO[0000][srpmpacker] Finding all SPEC files                       
              INFO[0003][srpmpacker] Calculating SPECs to repack                  
              PANI[0003][srpmpacker] unknown GOARCH detected (386)                
              panic: (*logrus.Entry) 0x9b6b5c0

              goroutine 1 [running]:
              github.com/sirupsen/logrus.(*Entry).log(0x9b6b500, 0x0, {0x9b70980, 0x1d})
                /root/go/pkg/mod/github.com/sirupsen/logrus@v1.9.3/entry.go:260 +0x461
              github.com/sirupsen/logrus.(*Entry).Log(0x9b6b500, 0x0, {0x9b8ddbc, 0x1, 0x1})
                /root/go/pkg/mod/github.com/sirupsen/logrus@v1.9.3/entry.go:304 +0x73
              github.com/sirupsen/logrus.(*Entry).Logln(0x9b6b500, 0x0, {0x9b8de00, 0x1, 0x1})
                /root/go/pkg/mod/github.com/sirupsen/logrus@v1.9.3/entry.go:394 +0xc0
              github.com/sirupsen/logrus.(*Logger).Logln(0x98ae4b0, 0x0, {0x9b8de00, 0x1, 0x1})
                /root/go/pkg/mod/github.com/sirupsen/logrus@v1.9.3/logger.go:298 +0x75
              github.com/sirupsen/logrus.(*Logger).Panicln(...)
                /root/go/pkg/mod/github.com/sirupsen/logrus@v1.9.3/logger.go:339
              github.com/microsoft/azurelinux/toolkit/tools/internal/logger.PanicOnError({0x8452cc0, 0x9b5afa8}, {0x0, 0x0, 0x0})
                /root/azurelinux/toolkit/tools/internal/logger/log.go:162 +0xc7
              main.main()
                /root/azurelinux/toolkit/tools/srpmpacker/srpmpacker.go:191 +0x9bc
              make: *** [/root/azurelinux/toolkit/scripts/srpm_pack.mk:107: /root/azurelinux/build/make_status/build_toolchain_srpms.flag] Error 2

      * I have not been able to get past this stage
