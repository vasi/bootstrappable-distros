# EasyOS

## Bootstrapping info

Upstream: https://easyos.org/

Bootstrapping documentation:

* [Blog post](https://bkhome.org/news/202112/how-to-cross-compile-850-packages-using-yoctoopenembedded.html)
* [woofq repository](https://github.com/bkauler/woofq)
* (OpenEmbedded repository](https://github.com/bkauler/oe-qky-scarthgap
))

Requirements: Linux with compilers

Automation: Yocto, and some scripts. Several manual steps

Integration testing: No

What you get: Unknown, it requires binaries

Can install further software from source: Maybe, if you install devx and figure out how to build PETs

Why it doesn't count: Uses lots of binaries even in a "bootstrap"

## Manual testing

Version: Scarthgap, woofq commit 14c830b

Architecture: x86_64

Date: 2025-07-02

Build time: Over a day, incomplete

### Testing process

* Running on a Fedora 42 host
  * Using a Debian 12 VM
  * Needs over 500 GB of space in the VM!
* Install dependencies
  * `sudo apt install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 liblz4-tool locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd rxvt-unicode`
  Enable en_US.UTF-8: `dpkg-reconfigure locales`
* Setup Yocto/OpenEmbedded for EasyOS
  * `git clone https://github.com/bkauler/oe-qky-scarthgap.git ~/oe-qky-scarthgap`
  * `cd ~/oe-qky-scarthgap`
  * The scripts want a bind mount:
    * `sudo mkdir -p /mnt/build`
    * `sudo mount --bind $HOME /mnt/build`
  * Run the preparation script:
    * `mkdir -p /mnt/build/builds/oe/scarthgap`
    * `cd /mnt/build/oe-qky-scarthgap`
    * `sudo bash create-oe-quirky`
      * EasyOS wants a lot of things done as root, for unclear reasons
    * Enable running Tocto without root: `sudo chown -R $USER /mnt/build`
  * Configure Yocto
    * `cd /mnt/build/builds/oe/scarthgap/oe-quirky`
    * `source oe-init-build-env build-amd64`
    * Adjust BB_NUMBER_THREADS, PARALLEL_MAKE in conf/local.conf
* Run the Yocto build: `bitbake core-image-minimal`
* Fix all the build breakage
  * A _lot_ of packages need help building
  * Many downloads are broken, fetch them as needed. The Internet Archive is particularly useful: https://web.archiv  e.org/web/20200123111200/http://distro.ibiblio.org/quirky/quirky6/sources/t2/april/
  * Need to replace /bin/sh symlink with bash, some scripts assume we have bash
  * NetworkManager bug: https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/955. Just hack the name of "jansson" in the dep-check in meson.build, so it's not found
  * xresprobe: Add to recipe in do_configure: `sed -i 's%edid_monitor_descriptor_types%%' ${S}/ddcprobe/common.h`
    * Also, for some reason files are being marked as owned incorrectly. Open the xresprobe files.db with sqlite, and `update files set uid = 0, gid = 0;`
  * gimagereader is really hard to get working, cuz it wants to use native gobject introspection!
    * Edit recipe, add "qemu" to inherit, add "qemu-native python3 python3-pygobject gtk+3 gobject-introspection" to DEPENDS
    * Add do_configure:append() with: `sed -i -e 's%python3%PYTHONPATH=/mnt/build/builds/oe/scarthgap/oe-quirky/build-amd64/tmp/work/nocona-64-poky-linux/gimagereader/3.4.2/gimagereader-3.4.2/../recipe-sysroot/usr/lib/python3.12/site-packages qemu-x86_64 -r 5.15 -L /mnt/build/builds/oe/scarthgap/oe-quirky/build-amd64/tmp/work/nocona-64-poky-linux/gimagereader/3.4.2/gimagereader-3.4.2/../recipe-sysroot -E LD_LIBRARY_PATH=/mnt/build/builds/oe/scarthgap/oe-quirky/build-amd64/tmp/work/nocona-64-poky-linux/gimagereader/3.4.2/gimagereader-3.4.2/../recipe-sysroot/usr/lib /mnt/build/builds/oe/scarthgap/oe-quirky/build-amd64/tmp/work/nocona-64-poky-linux/python3/3.12.9/image/usr/bin/python3.12%' ../build/build.ninja`
    * This is totally cheating and relying on things outside the sysroot, but should be fine to just generate headers
  * refind: Add to oemake commands: 'CC="$CC" LD="$LD" EFIINC="=/usr/include/efi"  EFICRT0="${RECIPE_SYSROOT}/usr/lib" GNUEFILIB="${RECIPE_SYSROOT}/usr/lib"'
  * pup-tools: Nim has trouble finding its config. Remove --skipProjCfg from params, and copy ../recipe-sysroot-native/etc/nim/nim.cfg to ./nim
  * nim: Remove --skipParentCfg from recipe, and copy etc/nim.cfg to ./
  * inkscapelite: Add space before = in 'includedir =' in seds
  * inkspace:
    * Include cstdint in colorspace.h
    * Remove -lbacktrace and -DBOOST_STACKTRACE_USE_BACKTRACE in ninja.build
  * sgml-common: Change LIC_FILES_CKSUM
  * planner: Fix permissions with sqlite3, as above
  * symphytum: Remove the lines relating to Dropbox syncing, we don't have them and it probably no longer works
  * droidcam: Set 'S = "${WORKDIR}/droidcam-linux-client-1.8.2" in recipe
  * About 30 packages aren't found when the image is built. It looks like the "IMAGE_INSTALL:append" lines in conf/local.conf are often specifying packages that had no files selected
    * Were these miscompiled, or misconfigured? Do they just have the wrong names?
    * In any case, remove or replace them in conf/local.conf
  * About 6 selected packages have conflicts or other dependency issues, which need to be resolved by dropping packages. Some of these clearly make no sense together, like multiple versions of evince
* After much effort, we get a file tmp/deploy/images/genericx86-64/core-image-minimal-genericx86-64.rootfs-20250704014329.wic , looks like a raw qemu image
  * Boots with qemu: `qemu-system-x86_64 -bios /usr/share/OVMF/OVMF_CODE.fd -accel kvm -m 8g -drive file=core-image-minimal-genericx86-64.rootfs-20250704014329.wic,format=raw`
  * Openbox WM, need to right-click on desktop to launch things. But a lot is installed, eg: GIMP
  * This is a running Linux system, but not really the _distro_, it doesn't feel anything like EasyOS. We'll have to continue for that
* Export the packages for woofq
  * Get bacon from http://www.basic-converter.org/museum/bacon-3.9.3.tar.gz
    * Install: `configure && make -j1 && sudo make install`
  * cd /mnt/build/builds/oe/scarthgap/oe-quirky
  * sudo ./export-pkgs amd64
  We get 1800 .tar.xz packages in ../packages-oe-scarthgap, a package-list in * Packages-oe-scarthgap-official, and a list of homepages in PKGS_HOMEPAGES
* Setup woofq
  * ssh in as root with -Y, since the build wants to run an X terminal at some point!
  * Fetch woofq
    * `wget https://github.com/bkauler/woofq/archive/refs/heads/main.tar.gz`
    * `tar xvf main.tar.gz`
      * Whoa, there's binaries in the tarball! mksquashfs, kmod, debdb2pupdb, etc
      * At least they mostly look like things we know how to build
  * `cd woofq-main/easyos`
  * woofq expects some things to be present
    * `mkdir -p /mnt/build/builds/woof`
    * `cp easy-distro/amd64/oe/scarthgap/DISTRO_SPECS /etc`
    * `useradd -m spot`
    * `useradd -m fido`
    * `useradd -m zeus`
    * `groupadd filesgrp`
* Run woofq
  `./merge2out`
    * When asked, choose: amd64, oe, scarthgap
  * `cd /mnt/build/builds/woof/easy-out_amd64_amd64_oe_scarthgap/`
  * `./0setup`
  * `./1download`
    * This seems to download hundreds of PET binaries, from [files such as this](https://github.com/bkauler/woofq/blob/main/easyos/easy-distro/amd64/oe/scarthgap/Packages-pet-scarthgap-official). Includes critical things like the kernel and mesa
    * It's totally unclear how most of these can be built
      * At least the kernel has [build intsructions](https://distro.ibiblio.org/easyos/source/kernel/6.12.x/6.12.10-20250119/)
    * It looks like these PET files end up written to the 
* At this point, this isn't really a "bootstrappable" distro anymore, so I'll stop
