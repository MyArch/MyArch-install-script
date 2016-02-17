This script is a fork of CarlDuff work. Check out his awesome work if you want another
install-script : [CarlDuff](https://github.com/CarlDuff/aif-dev)

# [MyArch](https://github.com/Nandicre/MyArch) Install Script

Terminal setup for MyArch liveCD. You can use it without MyArch, it works fine
 on Arch vanilla :) (You may need some dependencies). The goal of
 this script is to help with Arch installation, and let you choose everything you
 want to install on your arch, without hidden packages installation. You can
 create a tty only system, or a GNOME or KDE (or whatever) system with hundreds
 of packages.

You can try it first in a virtual machine. Use it at your own risk !

## Prerequisites

- Obviously, an arch liveCD (original or based on)
- A working internet connection.
- Logged in as 'root'.
- This package : `dialog wipe`

If you find some packages not preinstalled in your favorite livecd, tell me, I will
 add them to the prerequisite packages.

## How to get it
### With git
- Update the package list and install git: `pacman -Sy git`
- Get the script: `git clone git://github.com/MyArch/MyArch-Install-Script`

### Without git
- Get the script: `wget https://github.com/MyArch/MyArch-Install-Script/tarball/master -O - | tar xz`

## How to use it

Simply run `install.sh` with a root user.
