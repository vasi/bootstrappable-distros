# Gnome OS

## Bootstrapping info

Upstream: https://os.gnome.org/

Bootstrapping documentation: No full docs, but:
* [gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta/-/blob/master/README.rst#gnome-os)
* [Bootstrappable Freedesktop slides](https://conf.linuxappsummit.org/event/5/contributions/177/attachments/37/63/Bootstrappable%20Freedesktop%20SDK%20-%20LAS%202023.pdf)
* [Bootstrappable Freedesktop merge request](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/merge_requests/11557)
* [freedesktop-sdk-binary-seed](https://gitlab.com/freedesktop-sdk/freedesktop-sdk-binary-seed)
* [BuildStream documentation](https://docs.buildstream.build/)

Requirements: A few common packages, and BuildStream

Automation: Mostly automated (BuildStream), but manual intervention needed to avoid binaries

Integration testing: [Yes, with Gitlab CI](https://gitlab.gnome.org/GNOME/gnome-build-meta/-/pipelines)

What you get: A full desktop

Can install further software from source: Yes, by building Flatpaks

## Manual testing

Version: Git commit 56b22734 (after Gnome 48)

Architecture: x86_64

Date: 2025-06-18

Build time: About one day

### Testing process

* Using Fedora 42 host. But it's just to run docker/podman, you could use anything
* Start a minimal Debian 12 container to build in
  * `mkdir -p buildstream-cache`
  * `podman run --privileged --name gnomeos -v $PWD/buildstream-cache:/root/.cache/buildstream -p 8080:8080 -ti debian:12`
    * We need privileges for bubblewrap and FUSE
* Install dependencies
  * `apt update`
  * `apt install -y bubblewrap fuse3 git lzip patch python3-dev g++ pipx make nano curl gpg caddy`
* Install BuildStream
  * `pipx install buildstream`
  * `pipx inject buildstream dulwich requests tomlkit`
  * `export PATH=/root/.local/bin:$PATH`
* Build the binary seed
  * `git clone https://gitlab.com/freedesktop-sdk/freedesktop-sdk-binary-seed.git`
    * We're at git commit ad06e5e4
  * `cd freedesktop-sdk-binary-seed`
  * `bst --log-file ~/live-bootstrap.log build -ignore-project-artifact-remotes bootstrap/base-sdk/live-bootstrap.bst`
  * `bst --log-file ~/binary-seed.log -o target_arch x86_64 build --ignore-project-artifact-remotes binary-seed.bst`
  * `bst -o target_arch x86_64 artifact checkout binary-seed.bst --directory /built_seed`
* Setup gnome-build-meta
  * `cd /`
  * `git clone https://gitlab.gnome.org/GNOME/gnome-build-meta.git`
  * `cd gnome-build-meta`
  * We'll use the [last known good build](https://gitlab.gnome.org/GNOME/gnome-build-meta/-/pipelines/860901): `git checkout 56b22734`
  * `make -C files/boot-keys clean`
  * `make -C files/boot-keys`
* Use our built seed as the basis for binary-seed-x86-64
  * This prevents a fetch of the binary data from a Docker registry
  * `bst workspace open --directory work_fdsdk freedesktop-sdk.bst`
  * `cp -a /built-seed work_fdsdk/built_seed`
  * `nano work_fdsdk/elements/bootstrap/base-sdk/binary-seed-x86_64.bst`
  * Edit the sources section to read:
```
sources:
- kind: local 
  path: built_seed
```
  * `bst build --ignore-project-source-remotes --ignore-project-artifact-remotes freedesktop-sdk.bst:bootstrap/base-sdk/binary-seed-x86_64.bst` 
  * `bst workspace close freedesktop-sdk.bst`
  * `rm -rf work_fdsdk`
* Continue building
  * `bst --log-file ~/gnomeos.log build --ignore-project-artifact-remotes gnomeos/live-image.bst`
* Try in qemu or a virtual machine
  * `bst artifact checkout gnomeos/live-image.bst --directory ./iso`
  * Back outside the container: `podman cp gnomeos:/gnome-build-meta/iso/disk.iso .`
  * [Run in qemu with UEFI](https://gitlab.gnome.org/GNOME/gnome-build-meta/-/wikis/Bootable-images-in-virtual-machines#running-manually-with-qemu-the-base-image), or an equivalent like Virt-Manager or Boxes
  * In the VM, install onto the virtual hard drive and reboot
  * Login, start a Console window, and setup ssh: `systemctl enable --now sshd`. Then you can SSH in
* Software installation
  * Binary Flatpaks can be installed with Gnome Software
  * A devel extension, which appears to be binary, [can be installed with updatectl](https://gitlab.gnome.org/GNOME/gnome-build-meta/-/wikis/gnome_os/Install-Software)
* Install the devel extension from source
  * Back in the container, in gnome-build-meta, build the sysupdate images: `bst build --ignore-project-artifact-remotes gnomeos/update-images.bst`
  * Serve it: `./utils/run-sysupdate-repo.sh --devel --same-version &`
  * Configure sysupdate for the VM:
    * SSH in while forwarding the port: `ssh -R8080:localhost:8080 gnomeos` (or whatever your VM's IP/hostname is)
    * `sudo mkdir -p /etc/sysupdate.d`
    * `sudo cp /usr/lib/sysupdate.d/*.transfer /etc/sysupdate.d/`
    * `sudo perl -i -pe 's,^Path=https.*,Path=http://localhost:8080/,' /etc/sysupdate.d/*.transfer`
  * In the VM, run the update: `sudo updatectl enable --now devel`
  * Reboot the VM, and now we have development tools like "gcc"
  * Notably, we can run `bst`, so we're self-hosting!
    * It emits a whole bunch of warnings, but they don't break anything
* What about installing Flatpaks from source?
  * First, disable existing Flatpak remotes, so we don't accidentally install binaries
    * `sudo flatpak remote-modify --disable flathub gnome-nightly`
    * `sudo flatpak remote-modify --disable flathub flathub`
  * Setup our VM for building from gnome-build-meta
    * Clone the repo, at the same commit ID
    * Copy the contents of files/boot-keys from the build container
    * Copy the contents of ~/.cache/buildstream from the container to the VM with a tool like rsync, so we don't have to rebuild them
    * Test that things are working: `bst artifact show sdk.bst` from inside gnome-build-meta should say it's "cached"
  * Build and install the Gnome Flatpak SDK:
    * `bst build --ignore-project-artifact-remotes flatpak-runtimes.bst`
    * `bst artifact checkout flatpak-runtimes.bst --directory ~/flatpak-repo`
    * `sudo flatpak remote-add --no-gpg-verify local ~/flatpak-repo`
    * `sudo flatpak install org.gnome.Sdk org.gnome.Platform`
  * Build and install a Flatpak app. Let's build [Extension Manager](https://github.com/mjakeman/extension-manager)
    * `git clone https://github.com/flathub/com.mattjakeman.ExtensionManager.git ~/extension-manager`
    * `cd ~/extension-manager`
    * Edit the JSON manifest file to remove the `runtime-version` key, since we have Gnome nightly 
    * `flatpak-builder --repo ~/flatpak-repo build com.mattjakeman.ExtensionManager.json`
    * `sudo flatpak install com.mattjakeman.ExtensionManager`
    * It runs!
  * Other Flatpaks may be easy or hard to install
    * Anything that uses just the Gnome or Freedesktop SDK, as well as flatpak-builder, will probably be pretty easy
    * If other SDKs/bases/extensions are used, eg: KDE or Wine or ffmpeg, you'll have to figure those out
    * Some Flatpaks don't use flatpak-builder normally at all, but expect a prebuilt binary, eg: Firefox. Good luck!
