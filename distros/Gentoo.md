# Gentoo

## Bootstrapping info

Upstream: https://www.gentoo.org/

Bootstrapping documentation: https://mid-kid.root.sx/git/mid-kid/bootstrap/src/branch/master/gentoo-2025/gentoo.txt

Requirements: Any Linux with Python

Automation: None

Integration testing: None

What you get: TODO

Can install further software from source: TODO

## Manual testing

Version: Portage tree as of 2025-01-01

Architecture: x86_64

Date: 2025-06-12

Build time: TODO 23:10

### Testing process

* We'll use the bootstrap procedure from mid-kid, starting from live-bootstrap. But it's likely possible to bootstrap directly from another distro.
* Using Fedora 42 host. But it's just to run docker/podman, you could use anything.
* Setup a container running Alpine 3.22: `podman run --name gentoo -ti alpine:3.22`
* In the container:
  * `apt add git bash curl python3 py3-requests`
  * `git clone -b 1.0 --depth=1 --recursive https://github.com/fosslinux/live-bootstrap`
  * `cd live-bootstrap`
  * `./download-distfiles.sh`
    * If anything fails to download with the right checksum, find it from another source
  * `./rootfs.py -c --external-sources --cores $(nproc)`