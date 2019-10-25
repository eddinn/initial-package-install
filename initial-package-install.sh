#!/usr/bin/env bash

# Author: Edvin Dunaway
# Contact: edvin@eddinn.net
# Version: 0.2.2

# TODO:

# Run as root with sudo
if (( EUID != 0 )); then
  printf -- '%s\n' "This script must be run with 'root' privileges, e.g 'sudo'" >&2
  exit 1
fi

# Try curl, else fall back to wget in a function
get_installer() {
  curl -L -O "${1:?No source defined}" || wget "${1}"
}

# Function for Ubuntu install
setup_ubuntu () {
  # Upgrade the system
  apt -y dist-upgrade

  # Define user Apt packages to install
  apt_packages=(
   audacity
   autoconf
   automake
   autopoint
   autotools-dev
   bash-completion
   chkrootkit
   chrome-gnome-shell
   curl
   dnsutils
   filezilla
   fonts-powerline
   gamemode
   gettext
   git
   gnome-common
   gnome-tweaks
   golang-go
   grub-customizer
   hexchat
   jq
   lame
   make
   mkchromecast
   mysql-common
   nfs-kernel-server
   nmap
   nodejs
   npm
   openjdk-8-jre
   openjdk-8-jre-headless
   openssh-server
   pkg-config
   powerline
   puppet
   puppet-lint
   python3
   python3-pip
   python3-venv
   qbittorrent
   remmina
   rkhunter
   rsync
   shellcheck
   snapd
   steam
   stow
   unattended-upgrades
   unzip
   vim
   vlc
   zip
   zsh
   zsh-syntax-highlighting
  )

  # Install all the defines user packages via apt with suggested packages
  printf -- '%s\n' "Installing user packages"
  apt install -y "${apt_packages[@]}"

  # Install latest stable Google Chrome, if not installed
  printf -- '%s\n' "Installing Google Chrome"
  if ! dpkg-query -W -f='${Status}' google-chrome-stable 2>/dev/null | grep -c "ok installed"; then
    # Try curl, else fall back to wget
    get_installer https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    apt install -y ./google-chrome-stable_current_amd64.deb
    rm -Rf ./google-chrome-stable_current_amd64.deb
  fi

  # Install TeamViewer, if not installed
  printf -- '%s\n' "Installing TeamViewer"
  if ! dpkg-query -W -f='${Status}' teamviewer 2>/dev/null | grep -c "ok installed"; then
    # Try curl, else fall back to wget
    get_installer https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
    apt install -y ./teamviewer_amd64.deb
    rm -Rf ./teamviewer_amd64.deb
  fi
}

# Function for Fedora install
setup_fedora () {
  # Upgrade the system
  dnf -y distro-sync

  # Define user RPM packages to install
  rpm_packages=(
   audacity
   autoconf
   automake
   bash-completion
   bind-utils
   chkrootkit
   chrome-gnome-shell
   curl
   filezilla
   gamemode
   gettext-devel
   git
   gnome-common
   gnome-tweaks
   golang
   grub-customizer
   hexchat
   libnfsidmap
   java-12-openjdk
   jq
   lame
   make
   mysql
   nfs-utils
   nmap
   nodejs
   npm
   openssh-server
   pkgconf-pkg-config
   powerline
   powerline-fonts
   puppet
   python3
   python3-pip
   qbittorrent
   remmina
   rkhunter
   rsync
   ShellCheck
   snapd
   steam
   stow
   unzip
   vim-enhanced
   vlc
   zip
   zsh
   zsh-syntax-highlighting
  )

  # Enable the Free and NonFree repos from RPM Fusion
  printf -- '%s\n' "Installing Free and NonFree RPM Fusion repo packages"
  dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm
  dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

  # Enabling Appstream data from the RPM Fusion repos
  printf -- '%s\n' "Core groupupdate"
  dnf -y groupupdate core

  # Install all the defined user packages via dnf
  printf -- '%s\n' "Installing user packages"
  dnf install -y "${rpm_packages[@]}"

  # Install latest stable Google Chrome, if not installed
  printf -- '%s\n' "Installing Google Chrome"
  if ! rpm -q google-chrome-stable 2>/dev/null | grep -c "google-chrome-stable"; then
    get_installer https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    dnf install -y ./google-chrome-stable_current_x86_64.rpm
    rm -Rf ./google-chrome-stable_current_x86_64.rpm
  fi

  # Install TeamViewer, if not installed
  printf -- '%s\n' "Installing TeamViewer"
  if ! rpm -q teamviewer 2>/dev/null | grep -c "teamviewer"; then
    get_installer https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm
    dnf install -y ./teamviewer.x86_64.rpm
    rm -Rf ./teamviewer.x86_64.rpm
  fi
}

# Determine what OS distro we are running..
# So far just Ubuntu and Fedora, since I use them the most.
host_distro=$(awk -F'=' '/^NAME=/ {print tolower($2)}' /etc/*-release 2>/dev/null | tr -d '"')
printf -- '%s\n' "Running on ${host_distro} distribution"

case "${host_distro}" in
  (ubuntu)  setup_ubuntu ;;
  (fedora)  setup_fedora ;;
  (*)  printf -- '%s\n' "Could not determine OS/Distro" >&2; exit 1 ;;
esac

printf -- '%s\n' "##########"
printf -- '%s\n' "Initial install finished, now run the post-initial.sh to finish the setup"
