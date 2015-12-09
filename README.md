# [MyArch](https://github.com/Nandicre/MyArch) Install Script

Terminal setup for MyArch liveCD. You can use it without MyArch, it works fine
 on Arch vanilla :) (with perhaps some needed package installation). The goal of
 this script is to help Arch installation, and let you choose everything you
 want to install on your arch, without hidden packages installation. You can
 create a tty only system, or a GNOME or KDE (or whatever) system with hundreds
 of software.

You can try it first within a virtual machine. Use it at your own risk !

## Prerequisites

- A working internet connection.
- Logged in as 'root'.
- This packages : `dialog`

If you find some packages not preinstalled in your favorite livecd, tell me, i
 add them to the prerequisite packages.

## How to get it
### With git
- Get list of packages and install git: `pacman -Sy git`
- get the script: `git clone git://github.com/Nandicre/MyArch-Install-Script`

### Without git
- get the script: `wget https://github.com/Nandicre/MyArch-Install-Script/tarball/master -O - | tar xz`

## How to use it

Simply run `install.sh` under root user.
