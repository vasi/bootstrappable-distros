# Guix

## Bootstrapping info

Upstream: https://guix.gnu.org/

Bootstrapping documentation: No complete docs, but these are useful:
* [Requirements](https://guix.gnu.org/manual/devel/en/html_node/Requirements.html)
* [Building from Git](https://guix.gnu.org/manual/devel/en/html_node/Building-from-Git.html)
* [Invoking guix system](https://guix.gnu.org/manual/devel/en/html_node/Invoking-guix-system.html)

Requirements: Linux with autotools, make, C/C++ compiler, Guile + several modules

Automation: Mostly automated, but several manual steps required to build system image

Integration testing: [Yes, with Cuirass](https://ci.guix.gnu.org/)

What you get: Any kind of system you can describe in a guix configuration, up to and including a desktop

Can install further software from source: Yes, with `guix system reconfigure`

Notes: 
* Guix will [rebuild everything from a tiny seed!](https://guix.gnu.org/en/blog/2023/the-full-source-bootstrap-building-from-source-all-the-way-down/). Though it does first have to build several deendencies on the host, and this excludes some systems such as Haskell/GHC, which are bootstrapped from binaries.
* The build process feels flaky, it took several tries to get it exactly right.

## Manual testing

Version: Git commit 670724e on 2025-05-04

Architecture: x86_64 

Date: 2025-06-04

Build time: About 3 days with i7-9750H

### Testing process

* The build process took many tries to get right due to bugs or other issues:
    * Guix needs many Guile packages, which few distros have. Guix's last release is years old, and building from git appears to need the _very new_ guile-git 0.10.0
    * Guix is unhappy building in a container
    * Guix [can fail to bootstrap as non-root](https://issues.guix.gnu.org/77862).
    * Guix [doesn't build with GCC 15](https://issues.guix.gnu.org/issue/77847)
    * Building on Fedora yielded mysterious post-bootstap errors about a badly typed repository location
    * Guix runs the tests for each package, which occasionally fail spuriously
* Let's build on Debian unstable, since the experimental distro tends to have [very up-to-date guix packages](https://tracker.debian.org/pkg/guix)
    * Install Debian trixie RC1
    * Upgrade to sid, and enable experimental
    * Install dependencies: `apt -t experimental build-dep guix`
* Build Guix
    * `git clone https://git.guix.gnu.org/guix.git`
    * `cd guix`
    * We only have Guile-Git 0.9.0, so choose the commit [before this one](https://codeberg.org/guix/guix/commit/86022e994e5fcb3918f2d3d2f6f89b24c5562910)
        * `git reset --hard 86022e9^`
    * Get GCC 14: `apt install g++-14`
    * `./bootstrap`
    * `CXX=g++-14 ./configure`
    * `make -j12 scripts/guix all`
    * `sudo make install`
* Authenticate
    * `git fetch origin keyring:keyring`
    * `guix git authenticate 9edb3f66fd807b096b48283debdcddccfea34bad "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"`
* [Setup the daemon](https://guix.gnu.org/manual/devel/en/html_node/Build-Environment-Setup.html) as root:
    * Although it's recommended to run unprivileged with user namespaces, some tests fail that way. Instead run as root.
    * `groupadd --system guixbuild`
    * `for i in $(seq -w 1 10); do useradd -g guixbuild -G guixbuild -d /var/empty -s $(which nologin) -c "Guix build user $i" --system guixbuilder$i; done`
    * Create dirs: `mkdir -p /gnu/store /var/guix /var/guix/tmp /var/log/guix /etc/guix`
    * Just run the daemon manually, rather than with systemd: `sudo env TMPDIR=/var/guix/tmp guix-daemon --max-jobs=3 --no-substitutes --build-users-group=guixbuild`
        * Set TMPDIR so our builds don't use up all RAM in a tmpfs.
* Pull:
    * `sudo install -d -o $USER /var/guix/profiles/per-user/$USER`
    * `guix pull -v3 -k`
            * This bootstraps from scratch, taking over a day
    * Setup profile: `export GUIX_PROFILE=/home/$USER/.config/guix/current; . "$GUIX_PROFILE"/etc/profile`
* Build a system image disk
    * Create a [custom system description file](../data/guix-no-subs.scm), to force compiling from source insead of using binary "substitutes"
    * Build an image: `guix system image --image-type=efi-raw --image-size=30GB --root=guix.img guix-no-subs.scm -v3 -k --timeout=360000 --max-silent-time=360000`
* It boots in QEMU, with UEFI turned on
    * Log in
    * Use `tune2fs -L my-root /dev/sda2` to label the filesystem to match the specification
    * Can `sudo guix pull -v3 -k --max-jobs=3`. This bootstraps all over again!
    * Put the guix-no-subs.scm file at /etc/config.scm, and `guix system reconfigure -v3 -k --max-jobs=3 /etc/config.scm`
        * This again does a full bootstrap
* You can follow up by editing your config to add other packages, services
    * You may want to expand the image first
