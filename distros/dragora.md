# Dragora

## Bootstrapping info

Upstream: https://www.dragora.org/

Bootstrapping documentation: https://cgit.git.savannah.gnu.org/cgit/dragora.git/tree/BOOTSTRAPPING.md

Requirements: Linux, with a C/C++ compiler

Automation: Mostly automated

Integration testing: None

What you get: A graphical desktop with Trinity

Can install further software from source: Yes, with the "qi" build tool

## Manual testing

Version: Git commit 71f4d119

Architecture: x86_64

Date: 2025-06-23

Build time: About 15 hours

### Testing process

* Using Arch Linux host. But it's just to run VMs, you could use anything.
* Build works best in a disposable VM, since it needs system tools. Using Debian 12, all following steps are in the Debian VM unless otherwise indicated
* Get dependencies: `sudo apt install -y bison build-essential file flex git lzip xorriso texinfo unzip zlib1g zlib1g-dev liblz1 liblz-dev wget rsync`
* Fetch sources
  * `git clone https://git.savannah.nongnu.org/git/dragora.git ~/dragora`
  * `cd ~/dragora/sources`
  * `wget -c -i SOURCELIST.txt -T 5 -t 1 -nc`
  * Some fail to download above, so fetch them from a slower mirror: `rsync -avP --ignore-existing rsync://mirror.fsf.org/dragora/v3/sources/ ./`
  * Validate: `sha256sum --quiet --check *.sha256`
* Bootstrap early stages
  * `cd ~/dragora`
  * `sudo ./bootstrap -s0 -j8`
  * `sudo ./bootstrap -s1 -j8`
* Use the bootstrap to build the rest of packages
  * `sudo ./enter-chroot` to enter a chroot
  * Inside the chroot:
    * `qi order /usr/src/qi/recipes/*.order | qi build -j8 -S -p -i -`
    * `passwd root`, and set a password
    * `exit` to exit chroot
* Build boot media
  * `sudo ./bootstrap -s2 -j8`
  * ISO is at ~/dragora/OUTPUT.bootstrap/stage2/cdrom/dragora-3.0_20250624-amd64-dvd.iso
* Use boot media in a VM
  * Setup a Virt-Manager VM. Configure with VGA graphics
  * Boot from ISO
  * In bootloader, choose "Boot Dragora Live"
  * Once booted and logged in, setup an MBR layout
    * `parted`
      * `mklabel msdos`
      * `mkpart primary linux-swap 1m 16g`
      * `mkpart primary ext3 16g 100%`
      * `quit`
  * Run `dragora-installer`
  * When asked for a package location, enter "/var/cache/qi"
  * Establish vda2 as ext3 mount point for /
  * When asked for software choices, just hit enter to install everything
  * Reboot the VM, and it should boot from disk
  * `startx`, and Trinity desktop runs. So retro!
* Building packages
  * We have all 700 or so packages already built, but we can still use qi to rebuild them, or build any new ones that are created
  * `git clone https://git.savannah.nongnu.org/git/dragora.git ~/dragora`
  * `qi build dragora/recipes/tools/parted`
