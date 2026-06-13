#!/usr/bin/env bash
set -euo pipefail

# Author: Edvin Dunaway
# Contact: edvin@eddinn.net
# Version: 0.3.1

if (( EUID != 0 )); then
  printf '%s\n' "This script must be run with root privileges, e.g. 'sudo ./initial-package-install.sh'" >&2
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  host_distro=${ID,,}
else
  printf '%s\n' "Could not read /etc/os-release" >&2
  exit 1
fi

log() {
  printf '\n%s\n' "==> $*"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

download_file() {
  local url=${1:?No source URL defined}
  local output=${2:?No output file defined}

  if command_exists curl; then
    curl -fsSL "$url" -o "$output"
  elif command_exists wget; then
    wget -q "$url" -O "$output"
  else
    printf '%s\n' "Neither curl nor wget is installed" >&2
    exit 1
  fi
}

is_deb_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

is_rpm_installed() {
  rpm -q "$1" >/dev/null 2>&1
}

apt_package_available() {
  apt-cache show "$1" >/dev/null 2>&1
}

install_available_apt_packages() {
  local packages=("$@")
  local available=()
  local skipped=()
  local package

  for package in "${packages[@]}"; do
    if apt_package_available "$package"; then
      available+=("$package")
    else
      skipped+=("$package")
    fi
  done

  if ((${#available[@]} > 0)); then
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${available[@]}"
  fi

  if ((${#skipped[@]} > 0)); then
    printf '\n%s\n' "Skipped unavailable Ubuntu packages:"
    printf '  - %s\n' "${skipped[@]}"
  fi
}

dnf_package_available() {
  dnf -q repoquery "$1" >/dev/null 2>&1 || rpm -q "$1" >/dev/null 2>&1
}

install_available_dnf_packages() {
  local packages=("$@")
  local available=()
  local skipped=()
  local package

  for package in "${packages[@]}"; do
    if dnf_package_available "$package"; then
      available+=("$package")
    else
      skipped+=("$package")
    fi
  done

  if ((${#available[@]} > 0)); then
    dnf install -y "${available[@]}"
  fi

  if ((${#skipped[@]} > 0)); then
    printf '\n%s\n' "Skipped unavailable Fedora packages:"
    printf '  - %s\n' "${skipped[@]}"
  fi
}

setup_ubuntu() {
  local apt_packages=(
    audacity
    autoconf
    automake
    autopoint
    autotools-dev
    bash-completion
    chkrootkit
    curl
    default-jre
    default-mysql-client
    dnsutils
    filezilla
    fonts-powerline
    gamemode
    gettext
    git
    gnome-browser-connector
    gnome-tweaks
    golang-go
    hexchat
    jq
    lame
    make
    mkchromecast
    nfs-kernel-server
    nmap
    nodejs
    npm
    openssh-server
    pipx
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
    steam-installer
    stow
    unattended-upgrades
    unzip
    vim
    vlc
    zip
    zsh
    zsh-syntax-highlighting
  )

  local optional_apt_packages=(
    grub-customizer
  )

  log "Updating Ubuntu package metadata"
  apt-get update

  log "Upgrading installed Ubuntu packages"
  DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

  log "Installing Ubuntu packages"
  install_available_apt_packages "${apt_packages[@]}"

  log "Installing optional Ubuntu packages when available"
  install_available_apt_packages "${optional_apt_packages[@]}"

  log "Installing Google Chrome"
  if ! is_deb_installed google-chrome-stable; then
    download_file https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb google-chrome-stable_current_amd64.deb
    DEBIAN_FRONTEND=noninteractive apt-get install -y ./google-chrome-stable_current_amd64.deb
    rm -f google-chrome-stable_current_amd64.deb
  else
    printf '%s\n' "google-chrome-stable is already installed"
  fi

  log "Installing TeamViewer"
  if ! is_deb_installed teamviewer; then
    download_file https://download.teamviewer.com/download/linux/teamviewer_amd64.deb teamviewer_amd64.deb
    DEBIAN_FRONTEND=noninteractive apt-get install -y ./teamviewer_amd64.deb
    rm -f teamviewer_amd64.deb
  else
    printf '%s\n' "teamviewer is already installed"
  fi
}

setup_fedora() {
  local fedora_version
  fedora_version=$(rpm -E %fedora)

  local rpm_packages=(
    audacity
    autoconf
    automake
    bash-completion
    bind-utils
    chkrootkit
    curl
    filezilla
    gamemode
    gettext-devel
    git
    gnome-browser-connector
    gnome-tweaks
    golang
    grub-customizer
    hexchat
    java-latest-openjdk
    jq
    lame
    libnfsidmap
    make
    mariadb
    nfs-utils
    nmap
    nodejs
    npm
    openssh-server
    pipx
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

  log "Upgrading Fedora packages"
  dnf -y distro-sync

  log "Enabling RPM Fusion repositories"
  dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"

  log "Refreshing Fedora package metadata"
  dnf -y groupupdate core

  log "Installing Fedora packages"
  install_available_dnf_packages "${rpm_packages[@]}"

  log "Installing Google Chrome"
  if ! is_rpm_installed google-chrome-stable; then
    download_file https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm google-chrome-stable_current_x86_64.rpm
    dnf install -y ./google-chrome-stable_current_x86_64.rpm
    rm -f google-chrome-stable_current_x86_64.rpm
  else
    printf '%s\n' "google-chrome-stable is already installed"
  fi

  log "Installing TeamViewer"
  if ! is_rpm_installed teamviewer; then
    download_file https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm teamviewer.x86_64.rpm
    dnf install -y ./teamviewer.x86_64.rpm
    rm -f teamviewer.x86_64.rpm
  else
    printf '%s\n' "teamviewer is already installed"
  fi
}

log "Detected distribution: ${host_distro}"

case "$host_distro" in
  ubuntu) setup_ubuntu ;;
  fedora) setup_fedora ;;
  *)
    printf '%s\n' "Unsupported OS/Distro: ${host_distro}" >&2
    exit 1
    ;;
esac

printf '\n%s\n' "Initial install finished. Run './post-initial.sh' as your normal user to finish the setup."
