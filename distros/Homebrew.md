# Homebrew/Linuxbrew

## Bootstrapping info

Upstream: https://brew.sh/

Bootstrapping documentation: https://docs.brew.sh/Installation#untar-anywhere-unsupported

Requirements: Linux/Mac with compilers, git and a very new Ruby

Automation: Mostly, though some adjustment needed due to Homebrew strongly wanting to use binaries

Integration testing: [Github Actions](https://github.com/Homebrew/brew/blob/main/.github/workflows/tests.yml)

What you get: A secondary package manager

Can install further software from source: Yes

Why it doesn't count: Not a bootable OS, just a secondary package manager

## Manual testing

Version: Git commit d46d315c

Architecture: x86_64

Date: 2025-05-09

Build time: 3 hours to get a toolchain on i7-9750H

### Testing process

* Using Fedora 42 host, building in a Debian 12 VM
* Dependencies for Homebrew and Ruby:
  * `sudo apt-get install build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc git curl`
* Build a very recent Ruby
  * Homebrew wants to download a binary "[portable ruby](https://github.com/Homebrew/homebrew-portable-ruby)", and only refrains if we have a very recent Ruby, version 3.4 or higher. We'll need to build this ourselves.
  * `cd`
  * `curl -O https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.4.tar.gz`
  * `tar -xf ruby-3.4.4.tar.gz`
  * `cd ruby-3.4.4`
  * `./configure`
  * `make -j12`
  * `sudo make install`
* Install Homebrew from source
  * `git clone https://github.com/Homebrew/brew ~/homebrew`
  * Homebrew now sees itself as a mostly-binary package manager. Source-based installs have only [tier 3 support](https://docs.brew.sh/Support-Tiers), and bug reports are not accepted for these.
    * We'll have to take some special steps to force it to use source.
  * Force it to use our Ruby: `export HOMEBREW_USE_RUBY_FROM_PATH=1`
  * Force it to rely on local package definitions, not reaching out to the network for each one: `export HOMEBREW_NO_INSTALL_FROM_API=1`
  * Hack it to prevent ourselves from accidentally fetching binary "bottles". Edit homebrew/Library/Homebrew/brew.sh to set "HOMEBREW_BOTTLE_DEFAULT_DOMAIN=http://notreal.example.com"
  * By default, Homebrew will attempt to install all dependencies using bottles, when possible. Hack it to prevent this, editing homebrew/Library/Homebrew/cli/args.rb so the method "build_from_source_formulae" looks like:
  
      class BuildAllFormulae < Array
        def include?(_); true; end
        def exclude?(_); false; end
        def +(_); self; end
      end

      sig { returns(T::Array[String]) }
      def build_from_source_formulae
        BuildAllFormulae.new
      end

  * Prevent Homebrew's self-updates from stomping on our hacks: `  export HOMEBREW_NO_AUTO_UPDATE=1`
* Setup Homebrew in our shell: `eval "$(~/homebrew/bin/brew shellenv)"`
* Install something: `brew install pixz -v`. It works!
* Setup a non-system toolchain
  * `brew install gcc binutils curl git make -v`
    * rtmpdump doesn't build with gcc 15, so do: `brew install --cc=gcc rtmpdump -v`
  * Put binutils and compilers in our path
    * `export PATH="$HOME/homebrew/opt/binutils/bin:$PATH"`
    * `ln -s gcc-15 ~/homebrew/bin/gcc`
    * `ln -s g++-15 ~/homebrew/bin/g++`
  * Uninstall system gcc, curl, etc. Keep only libc6-dev
  * Force Homebrew to use our built curl: `export HOMEBREW_FORCE_BREWED_CURL=1`
  * Homebrew has trouble setting a user agent with no curl at all in /usr/bin. Edit Library/Homebrew/brew.sh to set 'curl_name_and_version="curl 8.14.1"'
  * Try to install something with our toolchain: `brew install -v jq`. It works!
* Could try to install glibc package, but that seems dangerous
