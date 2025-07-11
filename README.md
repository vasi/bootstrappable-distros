# Bootstrappable Distros

It's always felt a bit odd to me when we call a distro "open source". With open source apps like Firefox or MariaDB, I can start with a only a compiler and some source, run a build, and end up running the app. But if I want to run an open source distro like Debian, the only way is to download hundreds of megs of binary Debian packages! Why can't I just build it from source, like I can with apps?

This is my list of distros that can be bootstrapped from source, starting from an entirely different operating system. You might use them for preventing Trusting Trust attacks, or proving provenance, or porting to new architectures. See the [Bootstrappable Builds](https://bootstrappable.org/) project for more.

# Distros

## Fully bootstrappable distros

These distros are fully bootstrappable, according to [my particular criteria for what counts](#what-counts). Each link explains more details about the distro, and shows how I reproduced the bootstrap myself.

Best case: Normal distros one might run on a desktop, with thousands of modern packages that can be easily installed, and no special bootstrap requirements:

* [FreeBSD](distros/FreeBSD.md)
* Gentoo - [via live bootstrap](distros/GentooScratch.md), or [via Gentoo Prefix](distros/GentooPrefix.md)
* [Guix](distros/Guix.md)
* [NetBSD](distros/NetBSD.md)

Targeted mainly at embedded systems, but can bootstrap on any computer and self-build packages:

* [T2 SDE](distros/T2-SDE.md)
* [Yocto](distros/Yocto.md)

Very limited package set:

* [Dragora](distros/dragora.md) - Only 700 packages, most very old
* [oasis linux](distros/oasis.md) - Only 200 packages
* [Sabotage](distros/Sabotage.md) - Only 1300 packages, most very old

Other limitations:

* [Chimera Linux](distros/Chimera.md) - Only bootstrappable from a handful of musl distros
* [Gnome OS](distros/GnomeOS.md) - Immutable distro, can't install packages in normal ways. Can build certain flatpaks
* [Linux From Scratch](distros/LFS.md) - Added software must be built by hand, though with [guidance](https://www.linuxfromscratch.org/blfs/view/stable/)
* [stagex](distros/stagex.md) - Targeted at containers, needs some extra work to be bootable on hardware. Only 400 packages.

## Honorable mentions

These systems are similar to bootstrappable distros, or are good efforts towards one, but don't fully meet my criteria.

Can bootstrap, has dev tools, but no package management:

* [live-bootstrap](distros/live-bootstrap.md)
* [toybox](distros/toybox.md)

Can bootstrap, but no working dev tools in target:

* [buildroot](distros/buildroot.md)
* [Haiku](distros/Haiku.md) - Dev builds are supposedly possible, but broke when I tried
* [LibreELEC](distros/LibreELEC.md)
* [OpenADK](distros/OpenADK.md)
* [PTXdist](distros/PTXdist.md)

Can bootstrap a package manager and a toolchain, but not a bootable OS:

* [Homebrew/Linuxbrew](distros/Homebrew.md)
* [Nix/NixOS](distros/NixOS.md) - Can attempt to make bootable, but it fails for me
* [pkgsrc](distros/pkgsrc.md)

Has a documented bootstrap procedure, but I wasn't able to get it working:

* [Adelie Linux](distros/Adelie.md)
* [CRUX](distros/CRUX.md)
* [Exherbo](distros/Exherbo.md)
* [stal/IX](distros/stal-ix.md) - Build completes, almost boots
* [Void Linux](distros/Void.md)

An effort in the right direction, but not eligible:

* [Alpine Linux](distros/Alpine.md) - Seems to require starting on Alpine
* arch-cross-bootstrap ([upstream](https://github.com/archlinux-riscv/archlinux-cross-bootstrap)) and Arch boostrap32 ([upstream](https://git.archlinux32.org/bootstrap32)) - Both require already running an Arch-based distro (on another architecture). Also untouched in 7 years.
* Debian rebootstrap ([upstream](https://salsa.debian.org/helmutg/rebootstrap)) - Requires already running Debian (on another architecture)
* [EasyOS](distros/EasyOS.md) - Uses many binary components packages.
* Funtoo Evolved Bootstrap ([upstream](https://www.funtoo.org/Funtoo:Metro/Evolved_Bootstrap)) - Worked as of 2024, but the repo required to bootstrap was taken down
* GoboALFS ([upstream](https://github.com/gobolinux/GoboALFS)) - Untouched in 8 years, doesn't seem to work
* [Slackware](distros/Slackware.md) - Uses several binary packages. Also broken bootstrap.
* [Spack](distros/Spack.md) - Not a bootable distro. Also broken bootstrap.
* tinycore compiler ([upstream](https://github.com/linic/tcc)) - Incomplete project

## To investigate

* OpenWrt

Any more ideas? Open an issue or a PR!

# What counts?

What distros count as "bootstrappable"? There's many criteria you could use, relating to reproducible builds, or the minimal size of binaries required, etc.

For my purposes, I'm considering as "bootstrappable" any distro (the "target-distro") that can be built from a different "build-distro", without downloading the target-distro's binary packages.

Requirements:

* Build requirements
    * I must be able to start by running a totally different build-distro. A different version or architecture of the same target-distro isn't good enough.
    * All software comprising the new distro must be built locally. No downloading of ISOs, or binary packages for the target-distro, the way debootstrap or pacstrap work.
* Distro runtime requirements
    * I should end up running a full target-distro, on a real computer or virtual machine. Not a chroot or container.
    * The resulting distro should feel like a normal installation of the target-distro, not some weird franken-distro with bits of the build-distro hanging around.
    * The distro should be able to run on real hardware. No hobby OSes that can only run in emulators.
    * The target distro should have at least some amount of maintenance. If there haven't been updates in five years, I'll probably skip it.
* Adding software
    * There should be a supported way to install more software, even if it's binary-only.
    * There should be a compiler that can build more software. Self-hosting is ideal. Purely embedded distros, Android, or demos don't fit the goals of this list.

Limits I allow on bootstrappability:

* It's ok if I need to install binary packages _for the build-distro only_, eg: to install a compiler.
* It's ok if only certain build-distros are usable, eg: if they must be using a certain libc, or a certain architecture.
* It's ok to use binary bootstrap compilers for software that is typically built that way, like Rust or OpenJDK.
* It's ok if the target-distro is not a source-based distro, and typically uses binary packages, as long as it has dev tools. Installing further software from source could be considered a solved problem with tools like pkgsrc, Gentoo Prefix or Nix.

Other preferences:

* Where possible, I build in a container or VM to be certain exactly what dependencies are needed.
* Where possible, I create a bootable image, to show that it's realistic to install on a new system.

# Similar projects

* [live-bootstrap-distro-build-scripts](https://github.com/ajherchenroder/live-bootstrap-distro-build-scripts)
* [mid-kid's bootstraps](https://mid-kid.root.sx/git/mid-kid/bootstrap/)

# License

© 2025 by Dave Vasilevsky, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
