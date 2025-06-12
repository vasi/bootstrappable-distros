# Bootstrappable Distros

It's always seemed subtly different when we call a distro "open source". With open source applications like Firefox or MySQL, I can start with a just a compiler and some source, perform a build, and end up running the app.

But if I want to run an open source distro like Debian, the only way to start is to download hundreds of megabytes of Debian binary packages! Why can't I just build it from some other operation system?

This could be important for solving Trusting Trust attacks, or proving provenance, or porting to new architecures. See the [Bootstrappable Builds](https://bootstrappable.org/) project for more.

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
* The target-distro should be self-hosting, able to build a new version of itself. Limited, embedded distros like Android are not the sort of thing I'm looking for.
* The target-distro should be an actual software distribution.
    * There should be a supported way to install more software, even if it's binary-only. A web browser is a good test-case
    * There should be a compiler that can build more software. Self-hosting is ideal.
    * Basically: embedded distros, Android, or demos don't fit the goals of this list.

Limits I allow:

* It's ok if I need to install binary packages for the build-distro, eg: to install a compiler.
* It's ok if only certain build-distros are usable, eg: if they must be using a certain libc.
* It's ok to use binary bootstrap compilers for software that is typically built that way, like Rust or OpenJDK.
* It's ok if D is not a source-based distro, and typically uses binary packages. Installing further software from source is already a solved problem with tools like pkgsrc, Gentoo Prefix, Linuxbrew or Nix.

## Fully bootstrappable distros

Links go to details. In each case, I've tried to start from a Docker container or fresh install of the build-distro, to make clear exactly what dependencies are required.

* [NetBSD](distros/NetBSD.md) - Fast and automated bootstrap
* [FreeBSD](distros/FreeBSD.md) - Complex bootstrap, but CI-tested
* [Linux From Scratch](distros/LFS.md) - Build dozens of packages by hand, but you might learn something!
* [Sabotage](distros/Sabotage.md) - Tiny distro built for bootstrapping

## Honorable mentions

Not real distros, since no package management:

* [live-bootstrap](distros/live-bootstrap.md) - Build up from a minimal seed

## License

© 2025 by Dave Vasilevsky, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
