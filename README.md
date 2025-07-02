# Bootstrappable Distros

It's always seemed subtly different when we call a distro "open source". With open source applications like Firefox or MySQL, I can start with a just a compiler and some source, perform a build, and end up running the app.

But if I want to run an open source distro like Debian, the only way to start is to download hundreds of megabytes of Debian binary packages! Why can't I just build it from some other operation system?

This could be important for solving Trusting Trust attacks, or proving provenance, or porting to new architecures. See the [Bootstrappable Builds](https://bootstrappable.org/) project for more.

## Fully bootstrappable distros

Each link explains more details about the distro, and shows how I reproduced the bootstrap myself. Listed are only distros that meet [my particular criteria for what counts](#what-counts) as "bootstrappable".

Best case: Normal distros one might run on a desktop, with thousands of modern packages that can be easily installed, and no special bootstrap requirements:

* [NetBSD](distros/NetBSD.md)
* [FreeBSD](distros/FreeBSD.md)
* [Guix](distros/Guix.md)
* [Gentoo](distros/Gentoo.md)

Minor limitations:

* [Yocto](distros/Yocto.md) - Targeted mainly at embedded systems, but can build thousands of packages even on target

Limited package set:

* [Sabotage](distros/Sabotage.md) - Only 1300 packages, most very old
* [Dragora](distros/dragora.md) - Only 700 packages, most very old
* [oasis linux](distros/oasis.md) - Only 200 packages

Other limitations:

* [Chimera Linux](distros/Chimera.md) - Only bootstrappable from a handful of musl distros. Has good package set
* [Gnome OS](distros/GnomeOS.md) - Immutable desktop, can build flatpaks but not normal packages
* [Linux From Scratch](distros/LFS.md) - Added software must be built by hand, though with [guidance](https://www.linuxfromscratch.org/blfs/view/stable/)
* [stagex](distros/stagex.md) - Has ~300 packages. Targeted at containers, needs manual intervention to boot, but can run on real hardware.


## Honorable mentions

Systems that are similar to a bootstrappable distro, or are good efforts towards one, but don't fully meet my criteria.

Can bootstrap, has working dev tools, but no package management:

* [live-bootstrap](distros/live-bootstrap.md)
* [toybox](distros/toybox.md)

Can bootstrap, but no working dev tools in target, can't self-host or install packages:

* [buildroot](distros/buildroot.md)
* [Haiku](distros/Haiku.md) - Dev builds are supposedly possible, but broke when I tried
* [OpenADK](distros/OpenADK.md)

Somewhat reasonable bootstrap process is described, but I wasn't able to get it working:

* [stal/IX](distros/stal-ix.md) - Build completes, almost boots
* [Void Linux](distros/Void.md)
* [Adelie Linux](distros/Adelie.md)
* [CRUX](distros/CRUX.md)

Good effort, but not eligible:

* [Debian rebootstrap](https://salsa.debian.org/helmutg/rebootstrap) - Can bootstrap, but requires already running Debian (on another architecture)
* [Arch bootstrap32](https://git.archlinux32.org/bootstrap32) - Too old
* [arch-cross-bootstrap](https://github.com/archlinux-riscv/archlinux-cross-bootstrap) - Too old, and requires already running an Arch-based distro (on another architecture)
* [tinycore compiler](https://github.com/linic/tcc) - Incomplete project
* [Funtoo Evolved Bootstrap](https://www.funtoo.org/Funtoo:Metro/Evolved_Bootstrap) - Worked as of 2024, but the repo required to bootstrap was taken down

## What counts?

What distros count as "bootstrappable"? There's many criteria one might use:

* Reproducible builds of packages, so one can verify that software was not subverted
* Clear provenance of builds
* Ability to cross-build onto a new architecture
* A tiny, human-auditable seed

For my purposes, I'm considering as "bootstrappable" any distro (the "target-distro") that can be built from a different "build-distro", without downloading the target-distro's binary packages.

Requirements:

* I must be able to start by running a totally foreign build-distro, not a different version/architecture of the same target-distro.
* All software from the new distro must be built locally. No downloading of ISOs, or binary packages for the target-distro, the way debootstrap or pacstrap work.
* I should end up running a full target-distro, on a real computer or virtual machine. Not a chroot or container.
* It should at least plausibly be able to run on real hardware, no hobby OSes that haven't yet reached that point.
* The final system should feel like a normal setup of the target-distro, able to run its package manager and other tooling. It should not feel like some sort of franken-distro, with remnants of the build-distro scattered about.
* The target-distro should be an actual software distribution.
    * There should be a supported way to install more software, even if it's binary-only. A web browser is a good test-case
    * There should be a compiler that can build more software. Self-hosting is ideal.
    * Basically: purely embedded distros, Android, or demos don't fit the goals of this list.
* The target distro should have at least some amount of maintenance. If there haven't been updates in five years, I'll probably skip it.

Limits I allow:

* It's ok if I need to install binary packages _for the build-distro only_, eg: to install a compiler.
* It's ok if only certain build-distros are usable, eg: if they must be using a certain libc, or a certain architecture.
* It's ok to use binary bootstrap compilers for software that is typically built that way, like Rust or OpenJDK.
* It's ok if the target-distro is not a source-based distro, and typically uses binary packages, as long as it has compilers. Installing further software from source could be considered a solved problem with tools like pkgsrc, Gentoo Prefix, Linuxbrew or Nix.

Other preferences:

* Where possible, I build in a container to be certain exactly what dependencies are needed.
* Where possible, I create a bootable image, to show that it's realistic to install on a new system.

## Similar projects

* [live-bootstrap-distro-build-scripts](https://github.com/ajherchenroder/live-bootstrap-distro-build-scripts)

## License

© 2025 by Dave Vasilevsky, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
