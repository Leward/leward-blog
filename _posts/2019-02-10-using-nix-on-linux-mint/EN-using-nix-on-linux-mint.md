---
layout:     post
title:      "Using Nix on Linux Mint"
slug:       using-nix-on-linux-mint
date:       2019-02-10 05:35:00 +0800
categories:
lang:       en
ref:        using-nix-on-linux-mint
excerpt_separator: <!--more-->
---

## Using Nix on Linux Mint

If you are currently happy with you package manager and installation, it is likely that you don't need Nix (need as vital need). However, Nix will provide you with some nice additions: 

- Atomic upgrades and rollback
- Multi-user package management: the packages I install or remove do not affect other users
- Allowing multiple versions of a package to be installed
- Setup of specific build environments (hello developers and Docker)

If you find enough benefits in those Nix features, a migration may be worthwhile.

Nix defines itself as a purely functional package manager. Here functional is to be understood as per the principles of [functional programming](https://www.keycdn.com/blog/functional-programming). Immutability, absence of side-effect and pure functions are elements of functional programming which allows Nix to have similar properties as a package manager. 

Upgrading to a newer version of Linux Mint, I decided to give Nix a try and write a follow-up blog post.

<!--more-->

## Installation

To install Nix, run the following command (this is the [multi-user installation](https://nixos.org/nix/manual/#sect-multi-user-installation)): 

    sh <(curl https://nixos.org/nix/install) --daemon

Always be careful when you install a downloaded script with `curl`. Verify the source is trusted, and do not hesitate to review the installation script. 

I like that the installation process tries its best being transparent about the different steps it is performing. 

*Note: there are two installation mode available: multi-user and single-user. In general multi-user is better and will let all the user of the systems use nix. However packages that you install as a user are not made available to the other users.*

In the future, it may not be necessary to run this script as nix is [now available on Debian](https://ftp-master.debian.org/new/nix_2.2.1-2.html).

## Uninstall

If you play with Nix and would like to remove it, this can be done easily and cleanly. This means you can give Nix a try without risking creating havoc in your system. 

Installing Nix is a matter of downloading and running a script. Uninstalling means undo whatever the script has done.

I advise to [refer to the manual](https://nixos.org/nix/manual/#sect-multi-user-installation), as multiple steps are required and they may change over time. 

## Common Commands

Searching for a package: `nix search packagename`

Installing a package: `nix-env -i packagename`

Removing a package: `nix-env -e packagename`

List installed packages: `nix-env -q` 

Upgrade packages: `nix-env -u`

## Caveats

### Nemo & Dropbox

I use Dropbox to sync my documents between devices. Dropbox and its Nemo integration are not available. You can still install it using the Mint Software Manager.

### Entries in the start menu

Entries in the desktop menu are not added. For this to work you need to configure the `XDG_DATA_DIR` environment variable. You can add to your `.profile` file:

    export XDG_DATA_DIRS=$HOME/.nix-profile/share/applications:"${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}"

Still doing so, does not make the entry appear after installing a new package with `nix-env -i`. However at the next restart, the entry is there. If you open the menu editor you should also see the icon

### Nix for other users

Logging-in as a different user, `nix` and `nix-env` may not be immediately  available. Running `source /etc/profile` should resolve it.

## Running two versions side-by-side

**TL;DR;** 

- At runtime, only one version of a package can be present
- Use nix-shell for your builds
- Nix default channel (nixpkgs) does not keep, nor allow you to reference a particular version of a library or application
- Nix works great to setup the build environment, but won't do a better job for the dependencies of your application if the ecosystem you are working already has some build and dependency management systems

Nix is said to allow to have several installations of a package installed. Let's try it:

    $ nix-env -i ruby
    installing 'ruby-2.6.1'
    
    $ ruby -v
    ruby 2.6.1p33 (2019-01-30) [x86_64-linux]
    
    $ nix-env -iA nixpkgs.ruby_2_3
    replacing old 'ruby-2.6.1'
    installing 'ruby-2.3.8'
    
    $ ruby -v
    ruby 2.3.8p459 (2018-10-18) [x86_64-linux]
    

What has happened here? The first installation of ruby is quite straightforward and works as expected. Where things are a little bit trickier is when installing an older version of ruby. 

To install ruby 2.3 we had to add the `-A` option and specify the package name as `nixpkgs.ruby_2_3`. 

The following two commands are similar (as long as `nixpkgs.ruby_2_3` points to the version 2.3.8 of ruby):

- `nix-env -iA nixpkgs.ruby_2_3`
- `nix-env -i ruby-2.3.8`

However note that running `nix-env -i ruby-2.3.7` does not work, because that version is not targeted by any nix package. The versions which work are the ones returned one running `nix-env -qa ruby`

General rule of thumb is to install with `niv-env -i` only applications that you want to be available globally for a particular user. As a developer, to make the most of out of nix, you will need to create your own nix expressions in order to ensure your build are replicable using `nix-shell`.

The philosophy in Nix is not to pinpoint to a specific version of a library or application, but to have a set dependencies which can be easily reproduced between environment. [Multiple versions are kept in nixpkgs (default Nix package repository) if there is a good reason to](https://github.com/NixOS/nixpkgs/issues/9682#issuecomment-138105069). This does not mean you can't do it, there are ways of doing it, playing with nix channels, but I would not consider it to be straightforward.

For this reasons, nix is not always ideal, nor the silver bullet for developers needing to troubleshot and target a specific version. 

Also here in our example, ruby2.6 has disappeared from the list when you run `nix-env -q`. For a given package, only one can be resolved at runtime. If you need ruby 2.3 for a specific build, nix-shell is there for that purpose. It creates a shell with all the required dependencies to run the build. 

Nix-shell is more useful when you need system libraries to be present such as when working in C. This is a bit less the case when you are already using a build and package manager such as Maven for Java, Cargo for Rust, NPM for Javascript. 

As a developer if I need to do some troubleshooting on a particular version of Ruby, a tool such as [RVM](https://rvm.io/) may be more appropriate. 

## Conclusion

I am a fairly beginner with Nix and wanted to give it try as it is quite different from the traditional system package managers. 

To make it work nicely with Linux Mint from a desktop user perspective, a few minor adjustment were needed, but overall the experience is pleasant. 

Nix works great for my use case of installing applications globally on my system.  Is it significantly better than the package manager which shipped with my distribution? To the level I am using it, a bit, but not significantly. I can find in Nix packages which are not yet available in the main Mint repositories or newer versions. 

As a developer to manage things like my versions of Java and Ruby, Rust, I will stick to tools such as [SDKMAN](https://sdkman.io/) and [rvm](https://rvm.io/).

If I were to work on C or C++ projects, I'd probably find more value to Nix for my builds. As a Java developer for example, you mostly need the JDK and Maven installed. 

If you are a bit more curious, did you there was a Linux distribution called [NixOS](https://nixos.org/)? There is also a series of introduction posts to Nix called [Nix Pills](https://nixos.org/nixos/nix-pills/index.html).

When I finished writing this blog post, here are the packages I have installed (I just reinstalled my system): 

    $ nix-env -q
    bat-0.9.0
    git-2.19.2
    htop-2.2.0
    idea-ultimate-2018.3.4
    jekyll-3.8.5
    jq-1.6
    keepassx2-2.0.3
    openttd-1.8.0
    vscode-1.30.2
