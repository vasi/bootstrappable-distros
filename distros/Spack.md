# Spack

## Bootstrapping info

Upstream: https://spack.io

Bootstrapping documentation: https://spack.readthedocs.io/en/latest/bootstrapping.html

Requirements: Any distro with a compiler

Automation: Theoretically, but bootstrap fails

Integration testing: [Github Actions](https://github.com/spack/spack/actions), but unclear if it covers a full source bootstrap

What you get: A package manager, not a distro

Can install further software from source: Yes

Why it doesn't count: It's not a distro, it's a package manager. Also, it doesn't bootstrap

## Manual testing

Version: Git commit d5c76443

Architecture: x86_64

Date: 2025-07-04

Build time: Unknown, incomplete

### Testing process

* Fedora 42 host, but it's just for running VMs
  * Could probably use a container, but I want to try building graphical software
  * We'll use a Debian 12 VM
* Dependencies: `apt install git python3 gcc g++ xz-utils unzip bzip2`
* Fetch: `git clone https://github.com/spack/spack.git`
* Initialize: `. ~/spack/share/spack/setup-env.sh`
* Try to bootstrap
  * `spack bootstrap list` to list available bootstrap methods
  * Disable binary methods, leaving only 'spack-install'
    * `spack bootstrap disable github-actions-v0.6`
    * `spack bootstrap disable github-actions-v0.5`
  * Check status, make sure we're not missing any external dependencies: `spack bootstrap status`
  * Bootstrap: `spack bootstrap now`
  * libiconv fails mysteriously, with a configure script that's just cut off after a certain length!
    * Don't see any references to this problem online, no idea how to fix it
