---
layout:     post
title:      "WSL Setup On a New Windows 11 machine for Go Development"
slug:       wsl-setup-windows-11-go-development
date:       2022-02-05 19:30:00 -0400
categories: 
lang:       en
ref:        wsl-setup-windows-11-go-development
excerpt_separator: <!--more-->
---

I used to run [Pop!_OS](https://system76.com/pop) on my desktop computer. It was great for working on side projects (Java, Go, PHP, etc. ). 

However, I also like to ride with [Zwift](https://www.zwift.com/) in the winter months. 

Linux compatibility is not great. After fighting my computer to get a dual boot running (I got some weird boot sector errors, that were on and and off) I decided to bite the bullet a put Windows as the only OS.

I mostly use my desktop for Zwift in the winter anyway. Recently I wanted to dig into some Go again on my free time and had to figure a setup that works for me. I decided to document my process in this post.

<!--more-->

## WSL Installation

I can't tell for older versions of Windows, but on my WIndows 11 install it was very simple an painless.

Open the Windows Terminal (finally a decent terminal application on Windows!) as Administrator and type: `wsl --install`.

It will use Ubuntu as the default distribution. I believe it is sane default for the vast majority of people. 

To jump to WSL mode, simply type the `ubuntu` command in the terminal.

**Check WSL version:**

```
> wsl --list --verbose

  NAME      STATE           VERSION
* Ubuntu    Running         2
```

**Check ubuntu version:**

```
> ubuntu

$ lsb_release -a

No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 20.04 LTS
Release:        20.04
Codename:       focal
```

Cool. We have, at the time of writing, the latest LTS version of Ubuntu (end of life April 2030).

## ZSH

I like to use ZSH with [oh-my-zsh](https://ohmyz.sh). 

In WSL run:

```bash
$ sudo apt install zsh

# Get the latest instructions at https://ohmyz.sh/#install 
$ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

You'll be asked if you want to use ZSH by default, and you should be good to go.

## Brew for Linux

For a dev environment, I usually want to have a very recent version of a package (latest Go, PHP, etc), with the possibility to install multiple versions at the same time. 

Unfortunately the Ubuntu package manager usually lags a couple of versions behind the latest software releases. 

For my dev dependencies, I had a good experience using Brew on a Mac at work. 
[Brew also exists for Linux](https://docs.brew.sh/Homebrew-on-Linux). I decided to give it a try.

```bash
# Get the latest instructions at https://brew.sh
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# After the installation you should be asked to run the following commands
$ echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
$ eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
$ sudo apt-get install build-essential

# Recommended: 
$ brew install gcc
```

## Golang

I am installing [Golang](https://go.dev) with `brew`.

```bash
$ brew install go

$ go version
go version go1.17.6 linux/amd64

# Where is go installed?
# It will be useful to know when setting up an IDE such as Goland
# Here GOROOT = /home/linuxbrew/Cellar/go/1.17.6
$ ls -l $(which go)
lrwxrwxrwx 1 leward leward 26 Feb  4 23:58 /home/linuxbrew/.linuxbrew/bin/go -> ../Cellar/go/1.17.6/bin/go
```

WSL paths in ny IDE (Goland) will look like: `\\wsl$\Ubuntu\home\leward\projects\go-play`

## Docker

Since we have installed and enabled the Windows Subsystem for Linux (WSL - version 2), we can also use the [Docker Desktop WSL 2 backend](https://docs.docker.com/desktop/windows/wsl/). 

Since we installed WSL 2, all should be setup to use the WSL 2 backend by default.

![Use the WSL 2 based engine](/assets/2022-02-05-wsl-windows11-setup/docker-wsl2-bakend.png)

One nice thing of using the WSL 2 based engine is that resource management is handled by Windows. Unlike Docker for Mac where you need to setup and properly size the VM used for docker. 

![With the WSL 2 backend, Windows is managing the resources](/assets/2022-02-05-wsl-windows11-setup/docker-wsl2-resources.png)

Let's try the Docker installation.

Run from the Windows terminal: `docker run -d -p 80:80 docker/getting-started`.

The cool thing is that it will also work when using the docker command from a WSL terminal.

![Docker commands works from the Windows terminal, but also the WSL terminal](/assets/2022-02-05-wsl-windows11-setup/docker-wsl2-in-ubuntu.png)

## Closing thoughts

It ain't much but this setup helps me get started quickly on Windows. It's been a couple of years I did not do any programming from a Windows machine and seeing some of the improvements made recently is refreshing. The Docker experience is even better than MacOS. 

I still prefer my old Pop_OS! setup as a development environment. But I am not - yet - frustrated by my Windows installation.

Also I have a Logitech Camera that works with Windows Hello. This is also something I really got to enjoy. You sit, and the computer recognizes you.