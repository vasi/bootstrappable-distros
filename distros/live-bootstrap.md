# live-bootstrap

## Bootstrapping info

Upstream: https://github.com/fosslinux/live-bootstrap

Bootstrapping documentation: [Quick start](https://github.com/fosslinux/live-bootstrap?tab=readme-ov-file#how-do-i-use-this)

Requirements: Any POSIX with a shell and Python. Starts from a tiny hex0 seed.

Automation: Entirely automated

Integration testing: [Yes](https://github.com/fosslinux/live-bootstrap/blob/master/.github/workflows/bwrap.yml)

What you get: A small system, with no package management

Can install further software from source: Only by hand, no instructions

Why it doesn't count: Not a real distribution with package management

## Manual testing

Version: Git commit f2d7fda

Architecture: x86

Date: 2025-06-11

Build time: 6 hours with i5-10310U

### Testing process

* Using Arch Linux x86_64 host. But it's just to run docker/podman, you could use anything.
* `docker run --name live-bootstrap --privileged -ti alpine:3.22`
* In the container:
  * `apk add python3 py3-requests qemu-system-x86_64 curl git xz`
  * `git clone --recursive https://github.com/fosslinux/live-bootstrap /live-bootstrap`
  * `cd /live-bootstrap`
  * `./rootfs.py --qemu --cores 8 --mirror http://samuelt.me/pub/live-bootstrap`
