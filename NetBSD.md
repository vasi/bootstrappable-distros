# NetBSD

## Bootstrapping info

Upstream: https://www.netbsd.org/

Bootstrapping documentation: [Cross-compiling NetBSD with build.sh](https://www.netbsd.org/docs/guide/en/chap-build.html)

Requirements: Any POSIX with a C++ compiler

Automation: Mostly automated

Integration testing: None

What you get: Base system, including minimal Xorg

Can install further software from source: With [pkgsrc](https://www.netbsd.org/docs/software/packages.html). May use binary components for some packages, such as Rust or JDK.

## Manual testing

Version: 10.1

Architecture: x86_64 

Date: 2025-05-27

Build time: 1h 30m with i7-9750H

### Testing process

* Using Fedora 42 host. But it's just to run docker/podman, you could use anything.
* Start a minimal Debian 12 container to build in: `podman run --name netbsd -ti debian`
* In container:
    * `apt update`
    * `apt install curl gcc g++ zlib1g-dev`
    * Fetch [all source tarballs for 10.1](https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/source/sets/) with curl
        * `curl -LO https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/source/sets/gnusrc.tgz`
        * `curl -LO https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/source/sets/sharesrc.tgz`
        * `curl -LO https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/source/sets/src.tgz`
        * `curl -LO https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/source/sets/syssrc.tgz`
        * `curl -LO https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/source/sets/xsrc.tgz`
    * Unpack tarballs: `for i in *.tgz; do tar -xf $i -C /; done`
    * `cd /usr/src`
    * `mkdir -p /usr/obj`
    * `./build.sh -U -u -j12 -m amd64 -a x86_64 -x tools`
    * `./build.sh -U -u -j12 -m amd64 -a x86_64 -x release`
    * `./build.sh -U -u -j12 -m amd64 -a x86_64 -x iso-image`
* `podman copy netbsd:/usr/obj/releasedir/images/NetBSD-10.1-amd64.iso .`
* Test in qemu 9.2.3
  * `qemu-img create -f qcow2 netbsd.qcow2 10g`
  * `qemu-system-x86_64 -accel kvm -hda netbsd.qcow2 -cdrom NetBSD-10.1-amd64.iso`
  * Boots and installs with default options. Disable binary packages.
  * Reboots into a fully installed system
* Can easily [setup pkgsrc](https://www.netbsd.org/docs/pkgsrc/getting.html), and install further software from source.