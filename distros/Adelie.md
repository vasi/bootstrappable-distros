# Adelie Linux

## Bootstrapping info

Upstream: https://www.adelielinux.org/

Bootstrapping documentation: https://git.adelielinux.org/adelie/bootstrap/-/blob/master/bootstrap

Requirements: Linux with compilers, and some common packages

Automation: Yes, but fragile shell scripts

Integration testing: No

What you get: Unknown, it didn't finish

Can install further software from source: Unknown

Why it doesn't count: Bootstrapping fails to progress past setting up abuild

## Manual testing

Version: bootstrap git commit b1467436

Architecture: x86_64

Date: 2025-06-26

Build time: Incomplete

### Testing process

* Setup VM
  * Using Arch Linux host. But it's just to run VMs
  * Building in a Debian 12 VM
  * `sudo apt install git gcc g++ make flex bzip2 xz-utils wget file libc6-dev libc6-dev-i386 libc6-dev-x32 qemu-user-static`
* Get code
  `git clone https://git.adelielinux.org/adelie/bootstrap.git ~/bootstrap`
  `git clone https://git.zv.io/toolchains/bootstrap.git ~/build/bootstrap`
  `(cd ~/build/bootstrap; git checkout 185a90045d8e6ac414971ae7729319ad1534295c)`
* Fixup issues
  * Lots of problems came up as the build scripts ran. In general, they're very hard to debug, often the script continues through errors until a later compounding error finally stops it
  * Many problems are just mirrors that are down:
    * In ~/build/bootstrap/bootstrap
      * Replace the gnuib.git URL "gnulib https://gitlab.com/freedesktop-sdk/mirrors/savannah/gnulib/-/archive/475eac69463f384419a3b5a8bd449a6876123fab/gnulib-475eac69463f384419a3b5a8bd449a6876123fab.tar.gz"
      * Replace the config.git URL with "config https://gitlab.com/freedesktop-sdk/mirrors/savannah/config/-/archive/4ad4bb7c30aca1e705448ba8d51a210bbd47bb52/config-4ad4bb7c30aca1e705448ba8d51a210bbd47bb52.tar.gz"
      * Just after the line with "prep j 1 ${M_MCM}/${V_MCM}/musl-cross-make", add lines:

            mkdir -p "${bdir}/${name}/sources"
            cp /home/vasi/build/mcmtools/sys/bin/config.sub "${bdir}/${name}/sources/"

    * In ~/build/bootstrap/prootemu
      * Replace queue.h URL with https://raw.githubusercontent.com/NetBSD/src/cfc26a5399a4ecd2cfd609306a65fc273430b742/sys/sys/queue.h
      * Prevent downloading binary Alpine rootfs. Just before 'Stage 1', add

            cp /usr/bin/qemu-x86_64-static ${DEST}/bin/qemu-x86_64
            exit 0

    * In ~/bootstrap/bootstrap, just after "cd musl-cross-make", add:

          mkdir -p sources
          cp /home/vasi/build/mcmtools/sys/bin/config.sub sources/

    * In ~/bootstrap/setup-abuild, just before util-linux section, add:

          mkdir -p /perlbin
          pushd /usr/bin
          for i in $(grep -l mcmtools/glue/bin/ *); do
              perl -pe 's,/\S+/mcmtools/glue/bin/,/bin/,g' $i > /perlbin/$i
              chmod --reference $i /perlbin/$i
          done
          popd
          export PATH="/perlbin:$PATH"
          export AUTOM4TE="/perlbin/autom4te"


* Run the build
  * `cd ~/bootstrap`
  * `./bootstrap x86_64 ~/build`
  * Eventually fails during setup-abuild muon bootstrap, complaining that it can't execute the bootstrap binary, and I can't work out what's wrong
