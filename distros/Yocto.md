# Yocto

## Bootstrapping info

Upstream: https://www.yoctoproject.org/

Bootstrapping documentation: 

* [Quick start](https://docs.yoctoproject.org/5.0.10/brief-yoctoprojectqs/index.html)
* [Working with Packages](https://docs.yoctoproject.org/dev-manual/packages.html#using-runtime-package-management)

Requirements: One of [a handful of supported distros](https://docs.yoctoproject.org/5.0.10/ref-manual/system-requirements.html#supported-linux-distributions), though others may work with the right packages. A reasonable set of packages, including compilers and Python.

Automation: Nearly entirely automates

Integration testing: [Yes, with buildbot](https://autobuilder.yoctoproject.org/)

What you get: Anything you can define with Yocto layers and recipes. With the reference Poky, a small graphical image.

Can install further software from source: Yes, with the self-hosted package group

## Manual testing

Version: Scarthgap 5.0.10

Architecture: x86_64

Date: 2025-06-26

Build time: About 7 hours for core-image-sato-sdk plus packaging

### Testing process

* Using Fedora 42 host
  * But this isn't a supported build distro, so we'll run a Debian 12 VM
* Install [dependencies](https://docs.yoctoproject.org/5.0.10/ref-manual/system-requirements.html#ubuntu-and-debian) in the Debian VM: `sudo apt install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 liblz4-tool locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd`
  * `sudo dpkg-reconfigure locales`, enable en_US.UTF-8
* Fetch and configure (in the Debian VM)
  * `git clone git://git.yoctoproject.org/poky -b scarthgap ~/poky`
  * `cd ~poky`
  * `source oe-init-build-env` to enter the build-env
  * Edit conf/local.conf
    * Add to EXTRA_IMAGE_FEATURES: "package-management"
    * Add `IMAGE_INSTALL:append = " packagegroup-self-hosted"`
* Build, still in the Debian VM in the build-env: `bitbake core-image-sato-sdk`
* Outside the Debian VM, run in qemu:
  * Copy built files:
    * `rsync -avzLP debian12:poky/build/tmp/deploy/images/qemux86-64/core-image-sato-sdk-qemux86-64.rootfs.ext4 rootfs.ext4`
    * `rsync -avzLP debian12:poky/build/tmp/deploy/images/qemux86-64/bzImage .`
  * Create a disk to hold self-hosted tools: `qemu-img create -f qcow2 build.qcow2 200g`
  * Run: `qemu-system-x86_64 -accel kvm -m 31g -smp 12 -drive file=rootfs.ext4,format=raw -usb -device usb-tablet -device virtio-vga -net nic -net user,hostfwd=tcp::2222-:22 -kernel bzImage -append 'root=/dev/sda ip=dhcp' -drive file=build.qcow2`
* Setup the qemu VM for self-hosting:
  * Login as root: `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost`
  * Inside qemu as root:
    * `mkfs.ext4 /dev/sdb`
    * `mount /dev/sdb /mnt`
    * `useradd -m build -s /bin/bash`
    * `passwd build` to set a password
    * `chown -R build:build /mnt`
    * `su - build`
  * Inside qemu as the build user:
    * `git clone git://git.yoctoproject.org/poky -b scarthgap /mnt/poky`
* Build a source package
  * There are many available [recipes](https://layers.openembedded.org/layerindex/branch/scarthgap/recipes/)
  * Let's build [btop](https://layers.openembedded.org/layerindex/recipe/399250/) from the oe-meta repository
  * Still in qemu as the build user:
    * `git clone https://git.openembedded.org/meta-openembedded -b scarthgap /mnt/poky/meta-openembedded`
    * `cd /mnt/poky`
    * `source oe-init-build-env` to enter the build-env
    * Within the build-env:
      * Add our layer: `bitbake-layers add-layer ../meta-openembedded/meta-oe`
      * Build the package: `bitbake btop`
      * Build the package index: `bitbake package-index`
    * Serve our packages: `(cd /mnt/poky/build/tmp/deploy/rpm; python3 -m http.server 8888)`
      * Leave this runnig
* Install our source package in qemu (as root)
  * Setup the repo
    * `mkdir -p /etc/yum.repos.d`
    * `printf '[oe-packages]\nbaseurl=http://localhost:8888/\n' > /etc/yum.repos.d/oe-packages.repo`
    * `dnf makecache`
  * `dnf --nogpgcheck install btop`
* Try self-hosting an entire image (in qemu as build user)
  * `cd /mnt/poky`
  * `source oe-init-build-env` to enter the build-env
  * Within the build-env:
    * `bitbake core-image-minimal`
  * Resulting image is bootable
