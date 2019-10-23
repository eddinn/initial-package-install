#!/usr/bin/env bash

# Author: Edvin Dunaway
# Contact: edvin@eddinn.net
# Version: 0.1.10

# TODO:
# Combine with setup.sh
# Break the script down to specific app installs with dotfiles and addons

# Function for Ubuntu install
setup_ubuntu () {
  # Upgrade the system
  sudo apt -y dist-upgrade

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
   dnsutils
   filezilla
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
  )

  # Install all the defines user packages via apt with suggested packages
  echo -e '\nInstalling user packages'
  sudo apt install -y "${apt_packages[@]}"

  # Install latest stable Google Chrome, if not installed
  echo -e '\nInstalling Google Chrome'
  if [ "$(sudo dpkg-query -W -f='${Status}' google-chrome-stable 2>/dev/null | grep -c "ok installed")" -eq 0 ];
  then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb || curl -L -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm -Rf ./google-chrome-stable_current_amd64.deb
  fi

  # Install TeamViewer, if not installed
  echo -e '\nInstalling TeamViewer'
  if [ "$(sudo dpkg-query -W -f='${Status}' teamviewer 2>/dev/null | grep -c "ok installed")" -eq 0 ];
  then
    wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb || curl -L -O https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
    sudo apt install -y ./teamviewer_amd64.deb
    rm -Rf ./teamviewer_amd64.deb
  fi
}

# Function for Fedora install
setup_fedora () {
  # Upgrade the system
  sudo dnf -y distro-sync

  # Define user RPM packages to install
  rpm_packages=(
   audacity
   autoconf
   automake
   bash-completion
   bind-utils
   chkrootkit
   chrome-gnome-shell
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
  )

  # Enable the Free and NonFree repos from RPM Fusion
  echo -e '\nInstalling Free and NonFree RPM Fusion repo packages'
  sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm
  sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

  # Enabling Appstream data from the RPM Fusion repos
  echo -e '\nCore groupupdate'
  sudo dnf -y groupupdate core

  # Install all the defined user packages via dnf
  echo -e '\nInstalling user packages'
  sudo dnf install -y "${rpm_packages[@]}"

  # Install latest stable Google Chrome, if not installed
  echo -e '\nInstalling Google Chrome'
  if [ "$(sudo rpm -q google-chrome-stable 2>/dev/null | grep -c "google-chrome-stable")" -eq 0 ];
  then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm || curl -L -O https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    sudo dnf install -y ./google-chrome-stable_current_x86_64.rpm
    rm -Rf ./google-chrome-stable_current_x86_64.rpm
  fi

  # Install TeamViewer, if not installed
  echo -e '\nInstalling TeamViewer'
  if [ "$(sudo rpm -q teamviewer 2>/dev/null | grep -c "teamviewer")" -eq 0 ];
  then
    wget https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm || curl -L -O https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm
    sudo dnf install -y ./teamviewer.x86_64.rpm
    rm -Rf ./teamviewer.x86_64.rpm
  fi
}

# Determine what OS distro we are running..
# So far just Ubuntu and Fedora, since I use them the most.
OS=$(awk -F'=' '/^NAME=/ {print tolower($2)}' /etc/*-release 2>/dev/null | tr -d '"')
echo -e "Running on" "${OS}" 'distribution\n'

if [ "$OS" == "ubuntu" ]
then
 setup_ubuntu
elif [ "$OS" == "fedora" ]
then
 setup_fedora
fi

# Define Python3 Pip packages to install
pip_packages=(
 setuptools
 wheel
 ansible
 ansible-lint
 ansible-tower-cli
 pywinrm
 testresources
)

# Install Python3 pip packages
echo -e '\nUpgrading pip3 and installing Python3 packages'
# First, upgrade pip to latest version
sudo -H pip3 install pip --upgrade
# Install packages to user space
pip3 install --user "${pip_packages[@]}"

# Define Snap packages to install
snap_packages=(
 discord
 gitkraken
 spotify
)

# Install user snap packages
echo -e '\nInstalling VSCode and Slack with --classic'
sudo snap install code --classic
sudo snap install slack --classic
echo -e '\nInstalling Snap packages'
# Install the rest of the snap packages
for snaps in "${snap_packages[@]}";
do
 sudo snap install "$snaps";
done

# Install extensions for apps
echo -e '\nRunning setup scripts for apps extensions'
for ext in ./extensions/*-ext.sh;
do
 bash ./extensions/"$ext";
done

echo -e '\nAll done!'
