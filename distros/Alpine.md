# Alpine

## Bootstrapping info

Upstream: https://www.alpinelinux.org/

Bootstrapping documentation: https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/scripts/bootstrap.sh

Requirements: Unclear, may only work on Alpine

Automation: Seems automated?

Integration testing: No

What you get: ???

Can install further software from source: ???

Why it doesn't count: Doesn't seem to complete on a non-Alpine distro

## Manual testing

Version: Git as of 2025-07-10

Architecture: x86_64

Date: 2025-07-10

Build time: Incomplete

### Testing process

* Using Fedora 42 host, Debian 12 VM for building
* `sudo apt install git make gcc zlib1g-dev libssl-dev scdoc pkgconf libzstd-dev lua5.3 lua-zlib liblua5.3-dev meson wget bison flex texinfo zlib1g-dev bc pax-utils zip gawk libgmp-dev libmpfr-dev libmpc-dev linux-headers-amd64 libisl-dev gnat gdc`
* `export PATH="$PATH:/usr/sbin"`
* Install abuild
  * `cd`
  * `git clone https://gitlab.alpinelinux.org/alpine/abuild.git`
  * `cd abuild`
  * `make -j12`
  * `sudo make install`
  * `abuild-keygen -a`
  * `sudo mkdir -p /etc/apk/keys`
  * `sudo cp ~/.abuild/*.pub /etc/apk/keys/`
  * `sudo ln -sfn bash /bin/ash`
  * `sudo groupadd abuild`
  * `sudo usermod -a -G abuild $USER`
  * `sudo install -g abuild -m 775 -d /var/cache/distfiles`
* Install apk-tools
  * `cd`
  * `git clone https://gitlab.alpinelinux.org/alpine/apk-tools.git`
  * `cd apk-tools`
  * `meson setup build`
  * `meson compile -C build`
  * `sudo meson install -C build`
  * `sudo ldconfig`
  * `sudo apk --initdb add`
  * `ln -sfn /usr/local/apk /sbin/apk`
* Create an "apk-fake" script to fake package installation:

      #!/bin/sh
      for pkg in "$@"; do
        mkdir -p ~/fake
        cat > ~/fake/APKBUILD <<EOF
      pkgname="$pkg"
      pkgver=1.0
      pkgrel=0
      pkgdesc=fake
      arch=x86_64
      url=http://example.com
      license=MIT
      maintainer='me <me@example.com>'
      depends=''

      package() {
        mkdir -p "\$pkgdir"
      }

      check() {
        true
      }
      EOF
        (cd ~/fake && abuild -d -P ~/fake)
        sudo apk add ~/fake/$USER/x86_64/$pkg-1.0-r0.apk
      done
  
  * `apk-fake bison flex texinfo zlib-dev gcc gawk zip gmp-dev mpfr-dev mpc1-dev libucontext-dev gcc-gdc-bootstrap gcc-gnat-bootstrap linux-headers isl-dev`
* Bootstrap
  * Edit abuild, comment out "trace_apk_deps" for now since this won't work with a different libc
  * `cd`
  * `git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git`
  * `cd aports`
  * `apk --usermode --initdb add --root /home/vasi/toolchain`
  * `CBUILDROOT=$HOME/toolchain ./scripts/bootstrap.sh x86_64`
  * It keeps somehow deleting headers in /usr/include somehow! This is scary, and I'm stopping here
