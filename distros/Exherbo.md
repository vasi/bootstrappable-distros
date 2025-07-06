# Exerbo

## Bootstrapping info

Upstream: https://www.exherbo.org/

Bootstrapping documentation: https://www.exherbo.org/docs/bootstrapping.html

Requirements: Linux with some common packages

Automation: Not much, mostly manual

Integration testing: No

What you get: If it worked, a franken-distro that could be used as a stage3

Can install further software from source: Yes, with cave

Why it doesn't count: Couldn't complete a successful bootstrap

## Manual testing

Version: Paludis 3.0.1, repos as of 2025-07-04

Architecture: x86_64

Date: 2025-07-04

Build time: Incomplete

### Testing process

* Using Arch Linux host
  * Building in a Debian 12 VM, which will be destroyed
  * Running everything as root
* Setup
  * `apt install gcc g++ libtool pkg-config make gawk gettext git wget xz-utils asciidoc xmlto tidy file libpcre2-dev rsync libmagic-dev cmake libjansson-dev zlib1g-dev`
  * `export CHOST=x86_64-pc-linux-gnu`
  * `export PATH="/usr/$CHOST/bin:$PATH"`
* Build Eclectic
  * `cd`
  * `wget https://gitlab.exherbo.org/exherbo-misc/eclectic/-/archive/2.0.23/eclectic-2.0.23.tar.gz`
  * `tar xf eclectic-2.0.23.tar.gz`
  * `cd eclectic-2.0.23`
  * `./autogen.bash`
  * `./configure --build=${CHOST} --host=${CHOST} --prefix=/usr/${CHOST} --bindir=/usr/${CHOST}/bin --sbindir=/usr/${CHOST}/bin --libdir=/usr/${CHOST}/lib --datadir=/usr/share --datarootdir=/usr/share --docdir=/usr/share/doc/eclectic-2.0.22 --infodir=/usr/share/info --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var/lib`
  * `make -j8`
  * `make install`
* Build Paludis
  * `cd`
  * `wget https://distfiles.exherbolinux.org/paludis/paludis-3.0.1.tar.xz`
  * `tar xf paludis-3.0.1.tar.xz`
  * `cd paludis-3.0.1`
  * Fixup: In src/clients/cave/CMakeLists.txt, in  the target_link_libraries lists for cave and man-cave, put libpaludis at the end
  * This has switched from autotools to cmake, so we need a rather different setup command. This seems to be equivalent
  * `cmake -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=x86_64 -DCMAKE_INSTALL_PREFIX=/usr/$CHOST -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_INSTALL_LOCALSTATEDIR=/var/lib -DBUILD_SHARED_LIBS=OFF -DENABLE_GTEST=OFF -DENABLE_STRIPPER=OFF -DPALUDIS_DEFAULT_DISTRIBUTION=exherbo -DCONFIG_FRAMEWORK=eclectic -DPALUDIS_REPOSITORIES=all -DPALUDIS_ENVIRONMENTS=paludis -DPALUDIS_CLIENTS=cave -DUSE_PREBUILT_DOCUMENTATION=OFF .`
  * `make -j8 man-cave`
  * `PATH=$PWD/src/clients/cave:$PATH make -j8`
  * `make install`
* Setup users
  * `groupadd -g 443 paludisbuild`
  * `useradd -d /var/tmp/paludis -G tty -g paludisbuild -u 103 paludisbuild`
* Rebuild Eclectic, so it can see Paludis
  * `cd ~/eclectic-2.0.23`
  * `./configure --build=${CHOST} --host=${CHOST} --prefix=/usr/${CHOST} --bindir=/usr/${CHOST}/bin --sbindir=/usr/${CHOST}/bin --libdir=/usr/${CHOST}/lib --datadir=/usr/share --datarootdir=/usr/share --docdir=/usr/share/doc/eclectic-2.0.22 --infodir=/usr/share/info --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var/lib`
  * `make -j8`
  * `sudo make install`
* Setup config
  * Mostly as in bootstrap docs, with CHOST substituted. But some changes:
    * /etc/paludis/bashrc

          CHOST="x86_64-pc-linux-gnu"
          x86_64_pc_linux_gnu_CFLAGS="-march=native -O2 -pipe"
          x86_64_pc_linux_gnu_CXXFLAGS="-march=native -O2 -pipe"

    * options.conf: Set jobs=8
    * platforms.conf: use "amd64 ~amd64"
    * arbor.conf: set "profiles = ${location}/profiles/amd64"
    * installed.conf: tool_prefix: x86_64-linux-gnu-
    * 00basic
      * Add a line '# /etc/env.d/00basic' at the top, so it's detected as text
      * Temporarily add "/usr/x86_64-pc-linux-gnu/bin:/tmp/makeshift/tools" to PATH in file
    * bashrc: Add some lines to help dev tools find libraries:

          x86_64_pc_linux_gnu_CPPFLAGS="-isystem /usr/x86_64-pc-linux-gnu/include"
          x86_64_pc_linux_gnu_LDFLAGS="-L/usr/x86_64-pc-linux-gnu/lib"

  * Also create /etc/paludis/repositories/installed_unpackaged.conf , so we can fake package installation when needed:

        format = installed_unpackaged
        location = ${root}/var/db/paludis/repositories/installed_unpackaged

  * Create necessary directories:
    * `mkdir -p /var/db/paludis/repositories/installed /var/db/paludis/repositories/installed-unpackaged /var/db/paludis/repositories /var/log/paludis /var/cache/paludis/names /var/lib/exherbo/news /var/cache/paludis/metadata /var/tmp/paludis/build /var/cache/paludis/distfiles`
    * `chown -R paludisbuild:paludisbuild /var/tmp/paludis/build /var/cache/paludis/distfiles`
    * `chmod -R g+w /var/tmp/paludis/build /var/cache/paludis/distfiles`
    * `cave sync`, make sure it succeeds
  * Create tool symlinks
      * `mkdir /tmp/makeshift-tools`
      * `export PATH="$PATH:/tmp/makeshift-tools"`
      * `ln -s /usr/bin/x86_64-linux-gnu-gcc /tmp/makeshift-tools/x86_64-linux-gnu-cc`
      * `ln -s /usr/bin/x86_64-linux-gnu-gcc /tmp/makeshift-tools/x86_64-pc-linux-gnu-cc`
      * `ln -s /usr/bin/x86_64-linux-gnu-g++ /tmp/makeshift-tools/x86_64-linux-gnu-c++`
      * `ln -s /usr/bin/x86_64-linux-gnu-g++ /tmp/makeshift-tools/x86_64-pc-linux-gnu-c++`
      * `for i in ar as cpp gcc g++ ld nm objcopy objdump pkg-config ranlib readelf; do ln -s /usr/bin/x86_64-linux-gnu-$i /tmp/makeshift-tools/x86_64-pc-linux-gnu-$i; done`
  * Temporarily move a dir away so it doesn't interfere with compilation: `mv /usr/share/exherbo/banned_by_distribution{,.bak}`
  * `eclectic env update`
  * Fake some packages, so we can build our tools:
    * `mkdir -p /tmp/empty`
    * `cave import -x --location /tmp/empty sys-devel/autoconf 2.71 2.7`
    * `cave import -x --location /tmp/empty sys-devel/automake 1.16 1.17`
* Build initial packages
  `cave resolve -1z -0 '*/*' -x sys-devel/binutils`
  * Do the same to install dev-libs/gmp dev-libs/mpfr dev-libs/mpc sys-kernel/linux-headers
* Copy glibc libs/headers
  * `(dpkg -L libc6; dpkg -L libc6-dev) | perl -MFile::Basename -MFile::Path=make_path -MFile::Copy -ne 'chomp; next if -d; next unless m,^/usr/(include|lib),; ($dst = $_) =~ s,^/usr,/usr/$ENV{CHOST},; print "$_ => $dst\n"; $dir = dirname($dst); make_path($dir); copy($_, $dst);'`
  * `cp -R /usr/x86_64-pc-linux-gnu/include/x86_64-linux-gnu/* /usr/x86_64-pc-linux-gnu/include/`
  * `cp /usr/x86_64-pc-linux-gnu/lib/x86_64-linux-gnu/* /usr/x86_64-pc-linux-gnu/lib/`
* Build gcc
  * `cave resolve -1z -0 '*/*' -x 'sys-devel/gcc[threads]'`
  * But I can't get it to build easily, and the instructions don't mention anything
  * In general, I'm not a huge fan of this destructive method of bootstrapping, my system is now really messy and hard to fix.
