#!/usr/bin/env bash
set -euo pipefail

# Author: Edvin Dunaway
# Contact: edvin@eddinn.net
# Version: 0.3.3

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

install_keyring_from_url() {
  local url=${1:?No key URL defined}
  local keyring=${2:?No keyring path defined}

  download_file "$url" "${keyring}.tmp"
  gpg --dearmor --yes -o "$keyring" "${keyring}.tmp"
  rm -f "${keyring}.tmp"
  chmod 0644 "$keyring"
}

is_deb_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

is_rpm_installed() {
  rpm -q "$1" >/dev/null 2>&1
}

disable_teamviewer_apt_sources() {
  local file

  shopt -s nullglob
  local files=(/etc/apt/sources.list.d/teamviewer*.list /etc/apt/sources.list.d/teamviewer*.sources)
  shopt -u nullglob

  for file in "${files[@]}"; do
    [[ -e "$file" ]] || continue
    mv -f "$file" "${file}.disabled-by-initial-package-install"
    printf '%s\n' "Disabled TeamViewer APT source: $file"
  done
}

apt_update() {
  if apt-get update; then
    return 0
  fi

  printf '%s\n' "APT update failed. Disabling TeamViewer APT sources and retrying once." >&2
  disable_teamviewer_apt_sources
  apt-get update
}

apt_package_available() {
  apt-cache show "$1" >/dev/null 2>&1
}

install_available_apt_packages() {
  local packages=("$@")
  local skipped=()
  local package

  for package in "${packages[@]}"; do
    if ! apt_package_available "$package"; then
      skipped+=("${package} (not found)")
      continue
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get install -y "$package"; then
      continue
    fi

    skipped+=("${package} (dependency/install failure)")
    DEBIAN_FRONTEND=noninteractive apt-get -f install -y || true
  done

  if ((${#skipped[@]} > 0)); then
    printf '\n%s\n' "Skipped Ubuntu packages:"
    printf '  - %s\n' "${skipped[@]}"
  fi
}

dnf_package_available() {
  dnf -q repoquery "$1" >/dev/null 2>&1 || rpm -q "$1" >/dev/null 2>&1
}

install_available_dnf_packages() {
  local packages=("$@")
  local skipped=()
  local package

  for package in "${packages[@]}"; do
    if ! dnf_package_available "$package"; then
      skipped+=("${package} (not found)")
      continue
    fi

    if dnf install -y "$package"; then
      continue
    fi

    skipped+=("${package} (dependency/install failure)")
    dnf -y distro-sync || true
  done

  if ((${#skipped[@]} > 0)); then
    printf '\n%s\n' "Skipped Fedora packages:"
    printf '  - %s\n' "${skipped[@]}"
  fi
}

setup_ubuntu_apt_repos() {
  log "Installing APT repository helper packages"
  DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg wget

  install -d -m 0755 /etc/apt/keyrings

  log "Adding official Google Chrome APT repository"
  install_keyring_from_url https://dl.google.com/linux/linux_signing_key.pub /etc/apt/keyrings/google-linux.gpg
  cat >/etc/apt/sources.list.d/google-chrome.sources <<'EOF_SOURCES'
Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/google-linux.gpg
EOF_SOURCES

  log "Adding official Visual Studio Code APT repository"
  install_keyring_from_url https://packages.microsoft.com/keys/microsoft.asc /etc/apt/keyrings/microsoft.gpg
  cat >/etc/apt/sources.list.d/vscode.sources <<'EOF_SOURCES'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64 arm64 armhf
Signed-By: /etc/apt/keyrings/microsoft.gpg
EOF_SOURCES
}

install_teamviewer_ubuntu() {
  local deb_file=teamviewer_amd64.deb

  log "Installing TeamViewer"

  if is_deb_installed teamviewer; then
    printf '%s\n' "teamviewer is already installed"
    return 0
  fi

  if apt_package_available teamviewer && DEBIAN_FRONTEND=noninteractive apt-get install -y teamviewer; then
    return 0
  fi

  DEBIAN_FRONTEND=noninteractive apt-get -f install -y || true

  printf '%s\n' "TeamViewer APT package was not installable; trying the official TeamViewer .deb"
  download_file https://download.teamviewer.com/download/linux/teamviewer_amd64.deb "$deb_file"

  if DEBIAN_FRONTEND=noninteractive apt-get install -y "./${deb_file}"; then
    rm -f "$deb_file"
    return 0
  fi

  rm -f "$deb_file"
  DEBIAN_FRONTEND=noninteractive apt-get -f install -y || true
  printf '%s\n' "Skipped TeamViewer because both APT and the official .deb install failed." >&2
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
    code
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
    google-chrome-stable
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
  apt_update

  log "Upgrading installed Ubuntu packages"
  DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

  setup_ubuntu_apt_repos

  log "Updating Ubuntu package metadata after adding third-party repositories"
  apt_update

  log "Installing Ubuntu packages"
  install_available_apt_packages "${apt_packages[@]}"

  log "Installing optional Ubuntu packages when available"
  install_available_apt_packages "${optional_apt_packages[@]}"

  install_teamviewer_ubuntu
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
