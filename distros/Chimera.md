# Chimera Linux

## Bootstrapping info

Upstream: https://chimera-linux.org/

Bootstrapping documentation: https://github.com/chimera-linux/cports/blob/master/Usage.md#bootstrapping

Requirements: Linux with musl

Automation: Bootstrapping a build-root is mostly automated, but a fair amount of manual intervention was needed. Even more manual steps needed to get the system self-hosting.

Integration testing: Not for bootstrap

What you get: A basic command-line system

Can install further software from source: Yes, with [cports](https://github.com/chimera-linux/cports)

## Manual testing

Version: Git commit 8d8b19da

Architecture: x86_64

Date: 2025-06-22

Build time: 2 days

### Testing process

* Using Fedora 42 host. But it's just to run VMs, you could use anything
* Build process makes use of containers and loop devices, so we'll nned to run it in a VM
  * Needs to be a musl-using distro, that's not Alpine
  * Setup a Void Linux VM
  * Login as some user with sudo rights
* Setup package manager and dependencies
  * `sudo xbps-install -Syu xbps`
  * `sudo xbps-install -Syu`
  * `sudo xbps-install -Syu python openssl-devel git bubblewrap clang lld libunwind cmake meson patch pkgconf make ninja byacc flex perl m4 linux-headers curl zlib-devel zstd-devel llvm-libunwind-devel libcxx-devel autoconf automake libtool`
* Build apk 3.0
  * Needs to be 3.x, earlier versions aren't ok
  * `curl -OL https://gitlab.alpinelinux.org/alpine/apk-tools/-/archive/v3.0.0_rc4/apk-tools-v3.0.0_rc4.tar.gz`
  * `tar xf apk-tools-v3.0.0_rc4.tar.gz`
  * `cd apk-tools-v3.0.0_rc4`
  * Apply [patches](https://github.com/chimera-linux/cports/tree/master/main/apk-tools/patches). These are critical!
  * `meson setup -Dprefix=/ build`
  * `ninja -C build`
  * `sudo meson install -C build`
* Setup cports
  * `git clone --depth=1 https://github.com/chimera-linux/cports.git ~/cports`
  * `cd ~/cports`
  * `./cbuild keygen`
* Make a bunch of fixes in packages
  * python-urllib3 has a versioned dep on hatch_vcs that can't be satisfied. In main/python-urllib3/template.py, change the pkgver to 2.5.0, and sha256 to 3fc47733c7e419d4bc3f6b3dc2b4f890bb743906a30d56ba4a5bfa4bbff92760
  * Various packages depend on chimera-dinit targets in stage 3, which creates cirular deps. In src/cbuild/hooks/pkg/001_runtime_deps.py, find _scan_svc, and in the `for sv in scvreq:` loop add:
```
        if sv in ["pre-local.target", "early-devices.target", "pre-network.target"]:
           continue
```
  * elogind again requires the _scan_svn change, this time with "polkitd"
  * Some packages need "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" in their configure_args. Fix main/woff2/template.py and main/double-conversion/template.py
  * main/libvidstab/template.py needs `configure_args +=` to replace `=` in the `match` statement
  * main/rabbitmq-c/template.py needs the "cfi" hardening option removed, since it builds static libs
  * main/x265/template.py needs "--disable-asm" in configure_args, since nasm crashes when building it!
  * If any sources fail to download, just rerun the the command so it retries. Or find them elsewhere and place them in ./sources/$pkg
* Do the bootstrap: `./cbuild -C source-bootstrap`
  * This compiles packages three times, and takes a very long time
* Build some packages first to break circular dependencies
  * It's critical that we pass "-N", otherwise we'll fetch binaries
  * `./cbuild -CN pkg main/dinit-chimera`
  * `./cbuild -CN pkg main/elogind`
  * Now we can rever the _scan_svn changes
* Build packages needed for a boot image
  * `./cbuild -CN pkg main/dosfstools main/erofs-utils main/liminek main/mtools main/xorriso main/base-full main/base-live main/linux-kernel-zfs-bin`
* We'll need some tools later to make our system self-hosting, so build them now:
  * `./cbuild -CN pkg main/git main/bubblewrap`
  * This takes an exceedingly long time, git somehow pulls in ffmpeg, gtk+ and qt6!
* Build a bootable image
  * `git clone https://github.com/chimera-linux/chimera-live ~/chimera-live`
  * `cd ~/chimera-live`
  * `sudo ./mklive.sh -r ~/cports/packages/main -k ~/cports/etc/keys -p 'base-full base-live linux-stable-zfs-bin'`
  * We get 820 MB ISO chimera-linux-x86_64-LIVE-20250625.iso
* Boot our ISO, and install Chimera
  * Boot in VM
  * Start SSH with `dinitctl start sshd`, so we can login from outside the VM
  * Block the ISO from downloading binaries from the network: `touch /etc/apk/repositories.d/01-repo-main.list`
  * Setup disks
    * `cfdisk /dev/vda`: Partition with MBR
    * `mkswap /dev/vda1; swapon /dev/vda1`
    * `mkfs.ext4 /dev/vda2`
    * `mkdir /media/root`
    * `mount /dev/vda2 /media/root`
    * `chmod 755 /media/root`
  * Do a "local" install, avoiding the network: `chimera-bootstrap -l /media/root`
  * Have our new install use the packages we built, and not download binaries
  * From outside our Chimera VM, copy the cports packages we built to somewhere accessible: `rsync -avP cports/packages/ root@chimera:/media/root/var/lib/cports-packages/`
    * `touch /media/root/etc/apk/repositories.d/01-repo-main.list`
    * `mkdir -p /media/root/etc/apk/repositories.d`
    * Create /media/root/etc/apk/repositories.d/00-cports.list, containing:

          /var/lib/cports-packages/main
          /var/lib/cports-packages/main/debug
          /var/lib/cports-packages/user
          /var/lib/cports-packages/user/debug

* Back inside the VM, configure Chimera using a chroot: `chimera-chroot /media/root`. In the chroot:
  * `apk del base-live`
  * `genfstab / > /etc/fstab`
  * `passwd root`
  * `update-initramfs -c -k all`
  * `apk add grub-i386-pc`
  * `grub-install /dev/vda`
  * `update-grub`
  * `reboot`
* Setup our Chimera VM after it boots
  * Networking
    * `dinitctl enable dhcpcd`
    * `dinitctl enable sshd`
  * Setup a user, timezone, syslog, etc according to [manual](https://chimera-linux.org/docs/configuration/post-installation)
  * Consider using bash or another more featureful shell, BSD /bin/sh is pretty limited
* Setup self-hosting
  * Do this as a regular user, with doas rights
  * Setup cports repo
    * `doas apk add git bubblewrap`
    * `git clone --depth=1 https://github.com/chimera-linux/cports ~/cports`
    * `cd ~/cports`
    * `git fetch origin 8d8b19daf3dbb2fc2d5e3bbb53404cbcbc297ec2`
    * `git reset --hard 8d8b19daf3dbb2fc2d5e3bbb53404cbcbc297ec2`
    * `doas mv /var/lib/cports-packages packages`
    * `doas ln -s $PWD/packages /var/lib/cports-packages`
    * `doas apk update` to show that we can fetch
    * Copy signing keys from build VM to etc/keys. Find the name of your key, something like "build-xyz.rsa"
    * Create a config file in etc/config.ini, substituting your key name:

            [apk]
            repo = /var/lib/cports-packages

            [signing]
            key = build-xyz.rsa

    * Create a build root: `./cbuild binary-bootstrap`
  * Build a package: `./cbuild pkg main/squashfs-tools-ng`
    * Once built, it's installable with apk
