# Gentoo

## Bootstrapping info

Upstream: https://www.gentoo.org/

Bootstrapping documentation:
* [mid-kid's guide](https://mid-kid.root.sx/git/mid-kid/bootstrap/src/branch/master/gentoo-2025/gentoo.txt)
* [vapier's guide](https://wiki.gentoo.org/wiki/Porting#Preparing_a_seed_for_Catalyst)
* [Catalyst docs](https://wiki.gentoo.org/wiki/Catalyst)

Requirements: Any Linux with Python

Automation: Early steps all manual. Eventually emerge + Catalyst help

Integration testing: None

What you get: Either a minimal chroot, or a bootable ISO + stage3 ready for installation

Can install further software from source: Easily, with portage

## Manual testing

Version: Portage tree as of 2025-01-01

Architecture: x86_64

Date: 2025-06-12

Build time:
* About 12 hours for a basic chroot with i7-9750H
* Another day for installable media and stage3, including Rust built from source

### Testing process

* We'll use the bootstrap procedure from mid-kid, starting from live-bootstrap.
  * The only substantial differences are:
      * We make sure to setup /dev/shm, since some ebuilds require it
      * We use Catalyst aftewards to produce clean boot media
  * It's likely possible to bootstrap directly from another distro, taking much less time
* Using Fedora 42 host
  * It looks like this doesn't work well inside a podman container, so we'll build on the host
  * Dependencies: `dnf install git curl python3-requests`
* Build live-bootstrap:
  * `git clone -b 1.0 --depth=1 --recursive https://github.com/fosslinux/live-bootstrap`
  * `cd live-bootstrap`
  * `./download-distfiles.sh`
    * If anything fails to download with the right checksum, find it from another source
  * `./rootfs.py -c --external-sources --cores $(nproc)`
* Enter a chroot
  * `cd target`
  * `sudo mount -t devtmpfs devtmpfs dev/pts`
  * You should have mountpoints at proc, sys, dev, dev/pts, dev/shm
  * `sudo env -i TERM="$TERM" chroot . /bin/bash -l`
  * In the chroot:
    * `umask 022`
    * `source /steps/env`
  * The following steps all stay in the chroot, until otherwise mentioned
* Fetch some source
  * `mkdir -p /var/cache/distfiles; cd /var/cache/distfiles`
  * `curl -LO http://gitweb.gentoo.org/proj/portage.git/snapshot/portage-3.0.66.1.tar.bz2`
  * `curl -LO http://distfiles.gentoo.org/snapshots/squashfs/gentoo-20250101.xz.sqfs `
  * `curl -LO https://github.com/plougher/squashfs-tools/archive/refs/tags/4.6.1/squashfs-tools-4.6.1.tar.gz`
* Build squashfs-tools
  * `cd /tmp`
  * `tar xf /var/cache/distfiles/squashfs-tools-4.6.1.tar.gz`
  * `cd squashfs-tools-4.6.1`
  * `make -C squashfs-tools install INSTALL_PREFIX=/usr XZ_SUPPORT=1`
  * `cd ..; rm -rf squashfs-tools-4.6.1`
* Setup Gentoo repo
  * `unsquashfs /var/cache/distfiles/gentoo-20250101.xz.sqfs`
  * `mkdir -p /var/db/repos; mv squashfs-root /var/db/repos/gentoo`
* Setup portage in /tmp
  * `tar xf /var/cache/distfiles/portage-3.0.66.1.tar.bz2`
  * `ln -sf portage-3.0.66.1 portage`
* Configure portage
  * `echo 'portage:x:250:250:portage:/var/tmp/portage:/bin/false' >> /etc/passwd`
  * `echo 'portage::250:portage' >> /etc/group`
  * `mkdir -p /etc/portage/make.profile /etc/portage/profile`
  * `mv /bin/bzip2 /bin/bzip2.orig; ln -s bzip2.orig /bin/bzip2`
  * `echo '*/*' > /etc/portage/package.mask`
  * Setup the config files below:
```
cat > /etc/portage/make.profile/make.defaults << 'EOF'
FETCCOMMAND="curl -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
RESUMECOMMAND="curl -C - -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
FEATURES="-news -sandbox -usersandbox -pid-sandbox -parallel-fetch"
BINPKG_COMPRESS="bzip2"
ARCH="x86"
ABI="$ARCH"
DEFAULT_ABI="$ARCH"
ACCEPT_KEYWORDS="$ARCH"
CHOST="i386-unknown-linux-musl"
LIBDIR_x86="lib/$CHOST"
PKG_CONFIG_PATH="/usr/lib/$CHOST/pkgconfig"
IUSE_IMPLICIT="kernel_linux elibc_glibc elibc_musl prefix prefix-guest"
IUSE_IMPLICIT="$IUSE_IMPLICIT x86 amd64"  # dev-libs/gmp
IUSE_IMPLICIT="$IUSE_IMPLICIT sparc"  # sys-libs/zlib
USE_EXPAND="PYTHON_TARGETS PYTHON_SINGLE_TARGET"
USE="kernel_linux elibc_musl build"
SKIP_KERNEL_CHECK=y  # linux-info.eclass
EOF
cat > /etc/portage/package.use << 'EOF'
dev-lang/python -ensurepip -ncurses -readline -sqlite -ssl
EOF
cat > /etc/portage/package.unmask << 'EOF'
app-alternatives/bzip2
app-alternatives/ninja
app-arch/bzip2  # replaces files, live-bootstrap doesn't build libbz2
app-arch/lzip
app-arch/unzip
app-misc/pax-utils
app-portage/elt-patches
dev-build/autoconf
dev-build/autoconf-wrapper  # replaces files
dev-build/automake  # replaces files
dev-build/automake-wrapper  # replaces files
dev-build/make  # replaces files
dev-build/meson
dev-build/meson-format-array
dev-build/ninja
dev-lang/python
dev-lang/python-exec  # replaces files
dev-lang/python-exec-conf
dev-libs/expat
dev-libs/mpdecimal
dev-python/flit-core
dev-python/gentoo-common
dev-python/gpep517
dev-python/installer
dev-python/jaraco-collections
dev-python/jaraco-context
dev-python/jaraco-functools
dev-python/jaraco-text
dev-python/more-itertools
dev-python/packaging
dev-python/setuptools
dev-python/wheel
dev-util/pkgconf  # replaces files, dev-lang/python ebuild requires "--keep-system-libs" option when cross-compiling
net-misc/rsync
sys-apps/findutils  # replaces files, portage requires 4.9, live-bootstrap provides 4.2.33
sys-apps/gentoo-functions
sys-apps/portage
sys-devel/binutils-config
sys-devel/gcc-config
sys-devel/gnuconfig
virtual/pkgconfig
EOF
cat > /etc/portage/profile/package.provided << 'EOF'
acct-user/portage-0
app-alternatives/awk-0
app-alternatives/gzip-0
app-alternatives/lex-0
app-alternatives/yacc-0
app-arch/tar-1.27
app-arch/xz-utils-5.4.0
app-arch/zstd-0
app-crypt/libb2-0
app-crypt/libbz2-0
dev-build/autoconf-archive-0
dev-build/libtool-2.4.7-r3
dev-lang/perl-5.38.2-r3
dev-libs/libffi-0
dev-libs/popt-1.5
dev-python/platformdirs-4.2.2
dev-python/setuptools-scm-0
dev-python/trove-classifiers-2024.10.16
dev-util/re2c-0
sys-apps/baselayout-2.9
sys-apps/help2man-0
sys-apps/locale-gen-0
sys-apps/sandbox-2.2
sys-apps/sed-4.0.5
sys-apps/texinfo-7.1
sys-apps/util-linux-0
sys-devel/binutils-2.27
sys-devel/bison-3.5.4
sys-devel/flex-2.5.4
sys-devel/gcc-6.2
sys-devel/gettext-0
sys-devel/m4-1.4.16
sys-devel/patch-0
sys-libs/zlib-1.2.12
virtual/libcrypt-0
virtual/libintl-0
EOF
```
  * `grep '^PYTHON_TARGETS=\|^PYTHON_SINGLE_TARGET=' /var/db/repos/gentoo/profiles/base/make.defaults > /etc/portage/make.profile/make.defaults`

* Start building local dependencies
  * `MAKEOPTS=-j1 ./portage/bin/emerge -D1n app-arch/lzip dev-build/make`
  * `./portage/bin/emerge -D1n sys-apps/portage`
  * `emerge -D1n sys-devel/binutils-config`
  * `emerge -D1n sys-devel/gcc-config`
  * `emerge -D1n sys-devel/rsync`
* Configure a cross compiler
  * `echo 'PATH=/cross/usr/bin:/usr/bin' > /etc/env.d/50baselayout`
  * `env-update && source /etc/profile.env`
  * `mkdir -p /cross/etc/portage`
  * `ln -sf /etc/portage/make.profile /cross/etc/portage/make.profile`
```
cat > /cross/etc/portage/make.conf << 'EOF'
USE="prefix multilib"
CTARGET="x86_64-bootstrap-linux-gnu"
LIBDIR_x86="lib"
LIBDIR_amd64="lib64"
DEFAULT_ABI="amd64"
MULTILIB_ABIS="amd64 x86"
ACCEPT_KEYWORDS="amd64"
EOF
cat > /cross/etc/portage/package.use << 'EOF'
sys-devel/gcc -sanitize -fortran
EOF
mkdir -p /cross/etc/portage/env/sys-devel
cat > /cross/etc/portage/env/sys-devel/gcc << 'EOF'
EXTRA_ECONF='--with-sysroot=$EPREFIX/usr/$CTARGET --enable-threads'
EOF
cat > /cross/etc/portage/package.mask << 'EOF'
>=sys-devel/gcc-14
EOF
```
* Build the cross tools
  * `PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='headers-only' emerge -O1 sys-kernel/linux-headers`
  * `PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='headers-only -multilib' emerge -O1 sys-libs/glibc`
  * `PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-devel/binutils`
  * `PORTAGE_CONFIGROOT=/cross EPREFIX=/cross USE='-cxx' emerge -O1 sys-devel/gcc`
  * `PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-kernel/linux-headers`
  * `PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-libs/glibc`
  * `PORTAGE_CONFIGROOT=/cross EPREFIX=/cross emerge -O1 sys-devel/gcc`
* Configure cross tools
  * `mkdir -p /gentoo.cfg/etc/portage`
  * `ln -sf ../../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /gentoo.cfg/etc/portage/make.profile`
```
cat > /cross/usr/lib/gcc/x86_64-bootstrap-linux-gnu/specs << 'EOF'
*link:
+ %{!shared:%{!static:%{!static-pie:-dynamic-linker %{m32:/lib/ld-linux.so.2;:/lib64/ld-linux-x86-64.so.2}}}}
EOF
for tool in gcc g++; do
  rm -f /cross/usr/bin/x86_64-bootstrap-linux-gnu-$tool
  cat > /cross/usr/bin/x86_64-bootstrap-linux-gnu-$tool << EOF
#!/bin/sh
exec /cross/usr/i386-unknown-linux-musl/x86_64-bootstrap-linux-gnu/gcc-bin/*/x86_64-bootstrap-linux-gnu-$tool --sysroot=/gentoo "\$@"
EOF
 chmod +x /cross/usr/bin/x86_64-bootstrap-linux-gnu-$tool
done
cat > /cross/usr/bin/x86_64-bootstrap-linux-gnu-pkg-config << 'EOF'
#!/bin/sh
export PKG_CONFIG_SYSROOT_DIR=/gentoo
export PKG_CONFIG_LIBDIR=/gentoo/usr/lib64/pkgconfig:/gentoo/usr/share/pkgconfig
export PKG_CONFIG_SYSTEM_INCLUDE_PATH=/gentoo/usr/include
export PKG_CONFIG_SYSTEM_LIBRARY_PATH=/gentoo/lib64:/gentoo/usr/lib64
exec pkg-config "$@"
EOF
chmod +x /cross/usr/bin/x86_64-bootstrap-linux-gnu-pkg-config 
cat > /gentoo.cfg/etc/portage/make.conf << 'EOF'
FETCHCOMMAND="curl -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
RESUMECOMMAND="curl -C - -k --retry 3 -m 60 --ftp-pasv -o \"\${DISTDIR}/\${FILE}\" -L \"\${URI}\""
FEATURES="-news -sandbox -usersandbox -pid-sandbox -parallel-fetch"
BINPKG_COMPRESS="bzip2"
CBUILD="i386-unknown-linux-musl"
CHOST="x86_64-bootstrap-linux-gnu"
CFLAGS_x86="$CFLAGS_x86 -msse"  # https://bugs.gentoo.org/937637
CONFIG_SITE="$PORTAGE_CONFIGROOT/etc/portage/config.site"
USE="-* build $BOOTSTRAP_USE -zstd"
SKIP_KERNEL_CHECK=y  # linux-info.eclass
EOF
cat > /gentoo.cfg/etc/portage/package.use << 'EOF'
# https://gitweb.gentoo.org/proj/releng.git/tree/releases/portage/stages/profile/package.use.force/releng/alternatives
app-alternatives/lex flex
app-alternatives/yacc bison
app-alternatives/tar gnu
app-alternatives/gzip reference
app-alternatives/bzip2 reference
EOF
cat > /gentoo.cfg/etc/portage/config.site << 'EOF'
if [ "${CBUILD:-${CHOST}}" != "${CHOST}" ]; then
# https://gitweb.gentoo.org/proj/crossdev.git/tree/wrappers/site/linux
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no
fi
EOF
cat > /gentoo.cfg/etc/portage/package.mask << 'EOF'
>=sys-devel/gcc-14
EOF
```
* Build and setup the cross system
  * `pkgs_build="$(PORTAGE_CONFIGROOT=/gentoo.cfg python3 -c 'import portage
print(*portage.util.stack_lists([portage.util.grabfile_package("%s/packages.build"%x)for x in portage.settings.profiles],incremental=1))')"`
  * `PORTAGE_CONFIGROOT=/gentoo.cfg ROOT=/gentoo SYSROOT=/gentoo emerge -O1n sys-apps/baselayout sys-kernel/linux-headers sys-libs/glibc`
  * `PORTAGE_CONFIGROOT=/gentoo.cfg ROOT=/gentoo SYSROOT=/gentoo emerge -D1n $pkgs_build`
  * `mkdir -p /gentoo/etc/portage`
  * `ln -sf ../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0 /gentoo/etc/portage/make.profile`
  * `echo nameserver 1.1.1.1 > /gentoo/etc/resolv.conf`
  * `echo C.UTF-8 UTF-8 > /gentoo/etc/locale.gen`
  * Exit the chroot
  * `sudo umount dev/pts dev/shm dev sys proc`
  * `sudo cp -a var/db/repos gentoo/var/db/repos`
  * `sudo cp -a var/cache/distfiles gentoo/var/cache/distfiles`
* Chroot into the newly built system
  * `cd gentoo`
  * `sudo mount -t proc proc proc`
  * `sudo mount -t sysfs sysfs sys`
  * `sudo mount -t devtmpfs devtmpfs dev`
  * `sudo mount -t devpts devpts dev/pts`
  * `sudo mount -t tmpfs tmpfs dev/shm`
  * `sudo env -i TERM="$TERM" chroot . /bin/bash -l`
* In the new chroot, rebuild the new system
  * `umask 022`
  * `FEATURES='-sandbox -usersandbox' emerge -1 sys-apps/sandbox`
  * `emerge -1 sys-devel/binutils`
  * `emerge -o sys-devel/gcc`
  * `EXTRA_ECONF=--disable-bootstrap emerge -1 sys-devel/gcc`
  * `emerge -1 dev-lang/perl`
  * `USE='-filecaps -http2 -http3 -quic -curl_quic_openssl' emerge -e @system`
* Update the system
  * `emaint -a sync`
  * `emerge -avuDN @world`
  * `emerge -c`
* Configure portage, editing /etc/portage/make.conf. Something like this is reasonable:
```
MAKEOPTS="--jobs 12 --load-average 14"
EMERGE_DEFAULT_OPTS="--jobs 6 --load-average 14.0 --usepkg"
FEATURES="buildpkg binpkg-multi-instance"
```
* Prevent using binary Rust
  * We'll need Rust for some upcoming steps, but by default this will just use rust-bin, ie: downloaded binaries
  * We don't want to directly use downloaded binaries, only indirectly as a bootstrap stage
    * It's actually possible to use Gentoo to bootstrap from mrustc, but that takes forever
  * Fix this by bootstrapping Rust: `emerge dev-lang/rust`
  * Remove dependencies, including rust-bin: `emerge -c`
* This is now a workable chroot! But we may want clean stages and installation media
* Turn our root into a seed for Catalyst
  * `tar -C / --one-file-system --sort=name --exclude './var/cache/distfiles/*' --exclude './var/db/repos/*' --exclude './var/tmp' -cJvf /var/tmp/stage3-bootstrap.tar.xz .`
  * Copy this somewhere safe
* Setup a VM
  * We'd like to run Catalyst to make clean stages and boot media. But Catalyst doesn't like running in a chroot, so we'll turn ours into a VM
  * `passwd` to set a root password
  * Build a kernel: `USE='-initramfs' emerge --ask sys-kernel/gentoo-kernel`
  * Build a filesystem
    * `fallocate -l 50g /gentoo.img`
    * `mkfs.ext4 /gentoo.img`
    * `mount /gentoo.img /mnt`
    * `rsync -avx --exclude gentoo.img / /mnt/`
    * `umount /mnt`
  * Exit the chroot, and then run with qemu or another virtualization system, eg: `qemu-system-x86_64 -accel kvm -drive file=gentoo.img,format=raw -kernel boot/vmlinuz-6.12.31-gentoo-dist -append "root=/dev/sda"`
  * Get logged in via SSH
    * Login to the virtual system as root
    * Allow root SSH: `echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config`
    * Start SSH: `/etc/init.d/sshd start`
    * SSH in to the VM
* Setup Catalyst to build proper stages
  * From now on, we're in the VM
  * Install Catalyst
    * `mkdir -p /etc/portage/package.accept_keywords /etc/portage/package.use`
    * `echo dev-util/catalyst > /etc/portage/package.accept_keywords/catalyst`
    * `(echo sys-apps/util-linux python; echo sys-boot/grub grub_platforms_efi-32) > /etc/portage/package.use/catalyst`
    * `emerge dev-util/catalyst`
  * Setup our seed
    * `mkdir -p /var/tmp/catalyst/builds/default`
    * Copy our seed from above (eg: using scp) to /var/tmp/catalyst/builds/default/stage3-bootstrap.tar.xz
  * Configure by editing /etc/catalyst/catalyst.conf
    * Remove the "bindist" flag, this is for personal use
    * Set jobs and load-average appropriately
    * Make sure "binhost" is disabled
  * Get the repo snapshot: `catalyst --snapshot stable`
    * Note the "tree-ish" hash that was fetched to /var/tmp/catalyst
  * Clone the releng repo: `git clone https://gitweb.gentoo.org/proj/releng.git /var/tmp/catalyst/releng`
  * Force use of rust, over rust-bin, so we don't just download binaries
    * Edit /var/tmp/catalyst/releng/releases/portage/stages/package.mask/releng/rust, and change "dev-lang/rust-bin" to "dev-lang/rust"
    * Create /var/tmp/catalyst/releng/releases/portage/stages/profile/packages.build, and enter a line "dev-lang/rust" to force rust in stage1
  * Make some more fixes in /var/tmp/catalyst/releng/releases/portage/stages/package.use/releng/circular:
    * Change the net-misc/curl line to read "net-misc/curl http2 ssl openssl curl_ssl_openssl"
    * Add "dev-python/pillow -truetype"
* Use Catalyst to build stages
  * `cd /var/tmp/catalyst/releng/releases/specs/amd64`
  * Edit stage1-systemd-23.spec
    * Replace @TIMESTAMP@ with something reasonable, eg: "2025-06-12"
    * Replace @TREEISH@ with the hash from above, eg: "d55448fdd9e8e82386e9b121e4b637b03e59a0f8"
    * Replace @REPODIR@ with "/var/tmp/catalyst/releng"
    * Set source_subpath to "default/stage3-bootstrap", to use our bootstrapped seed
  * Build a stage1: `catalyst -v -f stage1-systemd-23.spec`
  * Edit stage3d-systemd-23.spec similarly to above
    * But this time, use the stage1 we just built as your source_subpath: "23.0-default/stage1-amd64-systemd-2025-06-12"
  * Build a desktop stage3: `catalyst -v -f stage3d-systemd-23.spec`
* Use Catalyst to build install media
  * Edit installcd-stage1.spec as before
    * For source_subpath, use our seed "default/stage3-bootstrap"
  * Edit /var/tmp/catalyst/releng/releases/portage/isos/package.accept_keywords/admincd-packages, and enter a line "net-libs/mbedtls"
  * Edit /var/tmp/catalyst/releng/releases/portage/isos/package.mask/releng/rust, and change the line to "dev-lang/rust-bin"
  * Build stage1: `catalyst -v -f installcd-stage1.spec`
  * Edit installcd-stage2-minimal.spec
    * Note there's more instances of @REPODIR@ and @TIMESTAMP@ to replace
    * In the livecd/unmerge list, change dev-lang/rust-bin to dev-lang/rust
  * Build an iso: `catalyst -v -f installcd-stage2-minimal.spec`
    * The resulting ISO is at /var/tmp/catalyst/builds/23.0-default/install-amd64-minimal-2025-06-12.iso
* Can use the ISO and stage3 to install Gentoo normally, on another machine
  * Be sure not to setup a binrepo if you want a fully-bootstrapped system
  * Adjust /etc/portage to eg: mask rust-bin
    * You may even want to mask `*/*-bin` to prevent any binary package installation
