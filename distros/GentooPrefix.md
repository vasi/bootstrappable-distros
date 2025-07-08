# Gentoo via Gentoo Prefix

This bootstrap first creates a Gentoo Prefix installation, which is already a software distribution (though non-bootable). Then it leverages that into a Gentoo chroot, and eventually an installable ISO. See the [Gentoo live-bootstra docs](GentooScratch.md) for a different approach.

## Bootstrapping info

Upstream: https://wiki.gentoo.org/wiki/Project:Prefix

Bootstrapping documentation:

* [Gentoo Prefix bootstrap](https://wiki.gentoo.org/wiki/Project:Prefix/Bootstrap)
* [mid-kid's guide](https://mid-kid.root.sx/git/mid-kid/bootstrap/src/branch/master/gentoo-2025/gentoo.txt)
* [Catalyst docs](https://wiki.gentoo.org/wiki/Catalyst)

Requirements: Any Linux with a compiler. Glibc distros are easiest.

Automation: Mostly automated

Integration testing: No

What you get:
* Initially, a secondary package manager on a foreign distro
* Later, a minimal chroot
* Finally, a bootable ISO

Can install further software from source: Yes, with emerge

## Manual testing

Version: Rolling

Architecture: x86_64

Date: 2025-07-07

Build time:
* 3.5 hours for Gentoo Prefix with  i7-9750H
* 3 more hours for a minimal chroot
* Another day or so for installable media and stage3

### Testing process

* Using Fedora 42 host, but only to run VMs
  * Ideally, we'd start with a minimal distro like Alpine. But Gentoo Prefix seems unhappy with a musl-based distro. It's probably possible to solve the problems, but let's just do it the easy way with a glibc-based distro.
  * Using a Debian 12 VM
* Install dependencies: `sudo apt install -y --no-install-recommends gcc g++ libc6-dev wget`
* Bootstrap a prefix
  * `cd ~`
  * `wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh`
  * `bash bootstrap-prefix.sh`
    * Choose 12 parallel jobs
    * Choose stable packages (the default)
    * Choose $HOME/gentoo as EPREFIX (the default)
  * libxcrypt appears to [fail](https://bugs.gentoo.org/932009), but then succeeds on retry, weird
* Configure Gentoo Prefix
  * Include gentoo's ld.so.conf in global one, run `sudo ldconfig`
  * Setup a make.conf/local.conf with any settings. Eg: FEATURES="buildpkg"
  * Enter the prefix: `~/gentoo/startprefix`
* We now have a Gentoo software distribution, but it's not bootable
  * This section is skippable, it just describes how usable Gentoo Prefix is as a "distro"
  * Can build all sorts of things, eg: `emerge pixz`
    * Some warnings look serious, but they're just because we're running as non-root
  * Can install and run xorg
    * Add a UTF-8 locale to ~/gentoo/etc/localgen, then run `locale-gen`
    * Set USE flags "elogind X -policykit"
      * Polkit tries to install things outside of the prefix, so we must avoid it
    * `emerge xinit xorg-server twm xterm --autounmask-write`
      * Accept changes with dispatch-conf, then re-run
    * Edit ~/gentoo/etc/X11/xinit/xserverrc, change /usr/bin/X to $HOME/gentoo/usr/bin/X
    * Without polkit, we can't automatically have permissions on devices changed. Do it manually: `sudo chown $USER /dev/tty* /dev/input/event*`
    * `startx`, and X comes up!
  * Can install graphical apps like icewm, firefox
    * May want to emerge rust first, then remove rust-bin, so we don't end up with binary packages installed
* From here, we can bootstrap a real Gentoo
  * Just jump straight to the cross-tools section of [the Gentoo live-bootstrap procses](GentooScratch.md), skipping the live-bootstrap and most of the portage-setup sections
  * From the portage-setup, we still need:
    * To create a portage user, and make sure the user has permissions to access the prefix (eg: with ACLs)
    * To create make.defaults, which was done earlier in the portage-setup stage
  * We also need to make a few adjustments, due to running on amd64 prefix, rather than x86 rooted:
    * Commands to build the final system need "EPREFIX=/"
    * Our make.defaults, gcc wrappers and make.conf need to be adjusted to the changed architecture
  * Finally, there's a couple of adjustments due to using a newer portage tree
      * We need set +gawk for app-alternatives/gawk
      * We may need to set gl_cv_func_strcasecmp_works=yes, to avoid a [cross-compilation bug](https://web.archive.org/web/20250424234848/https://savannah.gnu.org/bugs/?66978)
  * It may even be possible to skip the cross-tools section, and go straight to building a final system, but there are some difficulties:
    * Our prefix has no multilib, so we'd either need to build a no-multilib profile, or convert to multilib
    * Any modifications to reconfigure our toolchain may be destructive to our prefix environment
