#!/usr/bin/env bash
set -euo pipefail

script_path=$(realpath -e -- "${BASH_SOURCE[0]}")
repo_dir=$(dirname -- "$script_path")
readonly script_path repo_dir
mode=all
upgrade=0
repair=${FORCE_REINSTALL:-0}
only=
failures=()

usage() {
  cat <<'EOF'
Usage: ./initial-package-install.sh [--system | --user] [--upgrade] [--repair]

Run as your normal user for the full workstation setup. The system stage
uses sudo. An explicit root invocation runs the system stage only.

  --system   Install system packages and configure their repositories.
  --user     Set up apps, editor and desktop extensions and dotfiles.
  --upgrade  Also update existing packages, apps and extensions.
  --repair   Repair existing pipx environments, GNOME extensions and Oh My Zsh.
  --only=NAME  With --user, run one component: pipx, snaps, vscode, gnome,
               zsh or dotfiles.
  --help     Show this help.
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '\n==> %s\n' "$*"
}

run_step() {
  local label=$1
  shift
  log "$label"
  if "$@"; then
    return 0
  fi
  failures+=("$label")
  printf 'Failed: %s\n' "$label" >&2
}

finish() {
  if ((${#failures[@]})); then
    printf '\nSetup completed with failures:\n' >&2
    printf '  - %s\n' "${failures[@]}" >&2
    return 1
  fi
  printf '\nSetup complete.\n'
}

download() {
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 15 --max-time 180 --retry 2 --output "$2" "$1"
}

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-remove --no-upgrade "$@"
}

# A single conflicting package can block a whole batch on an existing system.
# Split only when the simulated transaction would remove installed packages.
apt_install_available() {
  local plan failed=0
  local packages=("$@")
  if ! plan=$(LC_ALL=C apt-get -s install --no-upgrade "$@" 2>&1); then
    printf '%s\n' "$plan" >&2
    return 1
  fi
  if ! grep -q '^Remv ' <<<"$plan"; then
    apt_install "$@"
    return
  fi
  if (($# == 1)); then
    printf 'Skipped %s. APT would remove: %s\n' "$1" \
      "$(awk '/^Remv / { print $2 }' <<<"$plan" | paste -sd ',')" >&2
    return 1
  fi

  local split=$(($# / 2))
  apt_install_available "${packages[@]:0:split}" || failed=1
  apt_install_available "${packages[@]:split}" || failed=1
  return "$failed"
}

apt_update() {
  apt-get -o APT::Update::Error-Mode=any update
}

package_installed() {
  if [[ $ID == ubuntu ]]; then
    [[ $(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null) == installed ]]
  else
    rpm -q "$1" >/dev/null 2>&1
  fi
}

install_available_packages() {
  local name candidates installable=() unavailable=()
  if [[ $ID == ubuntu ]]; then
    candidates=$(LC_ALL=C apt-cache policy "$@" |
      awk '/^[^ ]+:$/ { name=$1; sub(/:$/, "", name) } /Candidate: / && $2 != "(none)" { print name }') || return
  else
    candidates=$(dnf -q repoquery --available --queryformat '%{name}\n' "$@") || return
  fi
  for name; do
    if package_installed "$name"; then
      continue
    elif grep -Fxq -- "$name" <<<"$candidates"; then
      installable+=("$name")
    else
      unavailable+=("$name")
    fi
  done
  if ((${#unavailable[@]})); then
    printf 'Unavailable in the enabled repositories: %s\n' "${unavailable[*]}" >&2
  fi
  if ((${#installable[@]})); then
    if [[ $ID == ubuntu ]]; then
      apt_install_available "${installable[@]}" || return
    else
      dnf -y install "${installable[@]}" || return
    fi
  fi
  ((${#unavailable[@]} == 0))
}

configure_apt_repo() (
  local name=$1 source_name=$2 uri=$3 arches=$4 key_url=$5
  local component=${6:-main} suite=${7:-stable}
  local keyring="/etc/apt/keyrings/$name.gpg" temp existing=0
  if grep -qsF -- "$uri" /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; then
    printf 'Found an existing APT source for %s.\n' "$name"
    existing=1
    [[ -f $keyring ]] || return 0
  fi
  temp=$(mktemp -d) || return
  trap 'rm -rf -- "$temp"' EXIT
  download "$key_url" "$temp/key.asc" || return
  gpg --batch --no-options --homedir "$temp" --dearmor -o "$temp/key.gpg" "$temp/key.asc" || return
  install -d -m 0755 /etc/apt/keyrings || return
  if ! cmp -s "$temp/key.gpg" "$keyring"; then
    install -m 0644 "$temp/key.gpg" "$keyring" || return
  fi
  if ((!existing)); then
    if [[ $source_name == *.list ]]; then
      printf 'deb [arch=%s signed-by=%s] %s %s %s\n' \
        "$arches" "$keyring" "$uri" "$suite" "$component" >"$temp/source" || return
    else
      cat >"$temp/source" <<EOF || return
Types: deb
URIs: $uri
Suites: $suite
Components: $component
Architectures: $arches
Signed-By: $keyring
EOF
    fi
    install -m 0644 "$temp/source" "/etc/apt/sources.list.d/$source_name" || return
  fi
)

configure_vscode_rpm() {
  if grep -qsF 'https://packages.microsoft.com/yumrepos/vscode' \
    /etc/yum.repos.d/*.repo /etc/dnf/repos.d/*.repo /usr/share/dnf5/repos.d/*.repo; then
    return 0
  fi
  install -d -m 0755 /etc/yum.repos.d || return
  install -m 0644 /dev/stdin /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
}

enable_rpm_fusion() {
  local kind key
  local releases=()
  for kind in free nonfree; do
    if ! package_installed "rpmfusion-$kind-release"; then
      key="/usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-$kind-fedora-$VERSION_ID"
      [[ -r $key ]] || { printf 'Missing RPM Fusion signing key: %s\n' "$key" >&2; return 1; }
      rpm --import "$key" || return
      releases+=("https://download1.rpmfusion.org/$kind/fedora/rpmfusion-$kind-release-$VERSION_ID.noarch.rpm")
    fi
  done
  if ((${#releases[@]})); then
    dnf --setopt=localpkg_gpgcheck=1 -y install "${releases[@]}"
  fi
}

snap_installed() {
  command -v snap >/dev/null && timeout 5s snap list "$1" >/dev/null 2>&1
}

remove_snap_with_snapshot() {
  local name=$1
  # Keep an explicit snapshot even if automatic snapshots are disabled.
  snap save "$name" || return
  snap remove --purge "$name"
}

replace_apt_snap() {
  local installed=$1 name=$2 package
  shift 2
  if ! awk -v name="$name" '$1 == name { found = 1 } END { exit !found }' <<<"$installed"; then
    return 0
  fi
  for package; do
    if package_installed "$package"; then
      run_step "Replace $name Snap with $package" remove_snap_with_snapshot "$name"
      return
    fi
  done
  printf 'Keeping the %s Snap because its APT replacement is missing.\n' "$name" >&2
}

migrate_ubuntu_snaps() {
  local arch=$1 installed
  if ! command -v snap >/dev/null ||
    [[ ! -S /run/snapd.socket && ! -f /var/lib/snapd/state.json ]]; then
    return 0
  fi
  installed=$(LC_ALL=C timeout 15s snap list --all) || return

  case "$arch" in
    amd64|arm64|armhf) replace_apt_snap "$installed" code code ;;
  esac
  if [[ $arch == amd64 ]]; then
    replace_apt_snap "$installed" spotify spotify-client
    replace_apt_snap "$installed" slack slack-desktop
    replace_apt_snap "$installed" steam steam-launcher steam-installer
  fi
}

prepare_fedora_snaps() {
  if [[ $(readlink -f /snap 2>/dev/null) != /var/lib/snapd/snap ]]; then
    if [[ -e /snap || -L /snap ]]; then
      printf '/snap already exists and does not point to /var/lib/snapd/snap.\n' >&2
      return 1
    fi
    ln -sT /var/lib/snapd/snap /snap || return
  fi
  systemctl enable --now snapd.socket
}

install_ubuntu_steam_key() (
  local temp
  temp=$(mktemp -d) || return
  trap 'rm -rf -- "$temp"' EXIT
  download https://repo.steampowered.com/steam/archive/stable/steam.gpg "$temp/steam.gpg" || return
  install -m 0644 "$temp/steam.gpg" /usr/share/keyrings/steam.gpg
)

configure_ubuntu_steam() {
  local uri=https://repo.steampowered.com/steam/
  local keyring=/usr/share/keyrings/steam.gpg
  local source=/etc/apt/sources.list.d/steam-stable.list
  if ! dpkg --print-foreign-architectures | grep -Fxq i386; then
    dpkg --add-architecture i386 || return
  fi
  if grep -qsF -- "$uri stable steam" /etc/apt/sources.list /etc/apt/sources.list.d/*.list ||
    grep -qsF -- "$uri" /etc/apt/sources.list.d/*.sources; then
    printf 'Found an existing APT source for Steam.\n'
    return 0
  fi
  if [[ -e $source ]]; then
    printf 'Steam source already exists at %s. Review it before enabling the stable repository.\n' "$source" >&2
    return 1
  fi

  # Match the source and keyring shipped by Valve's steam-launcher package.
  install_ubuntu_steam_key || return
  install -m 0644 /dev/stdin "$source" <<EOF
deb [arch=amd64,i386 signed-by=$keyring] $uri stable steam
deb-src [arch=amd64,i386 signed-by=$keyring] $uri stable steam
EOF
}

install_ubuntu_slack() {
  # Slack's daily job would add a second APT source and globally trusted keys.
  if [[ -f /etc/apt/sources.list.d/workstation-slack.sources && ! -e /etc/default/slack ]]; then
    install -m 0644 /dev/stdin /etc/default/slack <<'EOF' || return
repo_add_once="false"
repo_reenable_on_distupgrade="false"
EOF
  fi
  # Slack recommends the PulseAudio server first. Use the ALSA library with
  # the system's existing audio server.
  apt_install --no-install-recommends slack-desktop libasound2t64
}

install_ubuntu_desktop_apps() {
  local need_steam=0
  # Spotify's installer only recognizes .list entries and creates one otherwise.
  run_step "Configure Spotify repository" configure_apt_repo \
    spotify spotify.list https://repository.spotify.com amd64 \
    https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc non-free
  run_step "Configure Slack repository" configure_apt_repo \
    slack workstation-slack.sources https://packagecloud.io/slacktechnologies/slack/debian/ amd64 \
    https://packagecloud.io/slacktechnologies/slack/gpgkey main jessie
  if ! package_installed steam-installer && ! package_installed steam-launcher; then
    need_steam=1
    run_step "Configure Steam repository" configure_ubuntu_steam
  fi

  log "Refreshing Ubuntu desktop app indexes"
  apt_update || return
  if ((need_steam)); then
    run_step "Install Steam and its graphics libraries" apt_install \
      steam-launcher steam-libs-amd64 steam-libs-i386:i386
  fi
  run_step "Install Spotify" install_available_packages spotify-client
  if ! package_installed slack-desktop; then
    run_step "Install Slack" install_ubuntu_slack
  fi
}

system_ubuntu() {
  local arch vendor_packages=()
  local optional=(
    audacity autoconf automake autopoint autotools-dev bash-completion bind9-dnsutils
    chkrootkit default-jre default-mysql-client filezilla fonts-powerline gamemode gettext
    gnome-browser-connector gnome-tweaks golang-go jq lame make
    nfs-kernel-server nmap nodejs npm openssh-server pkg-config powerline puppet
    puppet-lint python3-pip python3-venv qbittorrent remmina rkhunter rsync
    shellcheck snapd unattended-upgrades unzip vim vlc zip
  )

  # Removing Valve's launcher can leave its APT source without its keyring.
  if [[ ! -s /usr/share/keyrings/steam.gpg ]] &&
    grep -qsF 'signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam' \
      /etc/apt/sources.list.d/steam-stable.list; then
    log "Restore the Steam APT signing key"
    install_ubuntu_steam_key || return
  fi
  log "Refreshing Ubuntu package indexes"
  apt_update || return
  log "Installing setup dependencies"
  apt_install ca-certificates curl gnupg git pipx python3 stow zsh zsh-syntax-highlighting || return

  arch=$(dpkg --print-architecture)
  if [[ $arch == amd64 ]]; then
    run_step "Configure Google Chrome repository" configure_apt_repo \
      google-linux google-chrome.sources https://dl.google.com/linux/chrome/deb/ amd64 \
      https://dl.google.com/linux/linux_signing_key.pub
    vendor_packages+=(google-chrome-stable)
  fi
  case "$arch" in
    amd64|arm64|armhf)
      run_step "Configure Microsoft VS Code repository" configure_apt_repo \
        microsoft vscode.sources https://packages.microsoft.com/repos/code "$arch" \
        https://packages.microsoft.com/keys/microsoft.asc
      vendor_packages+=(code)
      ;;
  esac

  log "Refreshing Ubuntu indexes after repository setup"
  apt_update || return
  if ((upgrade)); then
    run_step "Upgrade installed Ubuntu packages" env DEBIAN_FRONTEND=noninteractive \
      apt-get -y --no-remove upgrade --with-new-pkgs
  fi
  run_step "Install Ubuntu workstation packages" install_available_packages "${optional[@]}"
  if ((${#vendor_packages[@]})); then
    run_step "Install Ubuntu vendor packages" install_available_packages "${vendor_packages[@]}"
  fi
  if [[ $arch == amd64 ]]; then
    run_step "Install Ubuntu desktop apps" install_ubuntu_desktop_apps
  fi
  run_step "Replace Ubuntu Snaps with installed APT editions" migrate_ubuntu_snaps "$arch"
}

system_fedora() {
  local arch vendor_packages=() optional=(
    audacity autoconf automake bash-completion bind-utils chkrootkit filezilla gamemode
    gettext-devel gnome-browser-connector gnome-tweaks golang
    java-latest-openjdk jq lame libnfsidmap make mariadb nfs-utils nmap nodejs24-npm-bin
    openssh-server pkgconf-pkg-config powerline powerline-fonts puppet python3-pip
    qbittorrent remmina rkhunter rsync ShellCheck snapd unzip vim-enhanced vlc zip
  )
  log "Refreshing Fedora package indexes"
  dnf makecache --refresh || return
  log "Installing setup dependencies"
  local -a required=(ca-certificates curl git pipx python3 stow zsh zsh-syntax-highlighting distribution-gpg-keys)
  if [[ $VERSION_ID == 45 ]]; then
    required+=(python3.14)
  fi
  dnf -y install "${required[@]}" || return

  arch=$(rpm --eval '%{_arch}')
  run_step "Enable RPM Fusion" enable_rpm_fusion
  case "$arch" in
    x86_64|aarch64)
      if ! snap_installed code; then
        run_step "Configure Microsoft VS Code repository" configure_vscode_rpm
        vendor_packages+=(code)
      fi
      ;;
  esac
  if [[ $arch == x86_64 ]] && ! snap_installed steam; then
    vendor_packages+=(steam)
  fi
  log "Refreshing Fedora indexes after repository setup"
  dnf makecache --refresh || return
  if ((upgrade)); then
    run_step "Upgrade installed Fedora packages" dnf -y upgrade
  fi
  run_step "Install Fedora workstation packages" install_available_packages "${optional[@]}"
  if ((${#vendor_packages[@]})); then
    run_step "Install Fedora vendor packages" install_available_packages "${vendor_packages[@]}"
  fi
  if package_installed snapd; then
    run_step "Prepare Fedora Snap support" prepare_fedora_snaps
  fi
}

select_pipx_python() {
  local version candidate
  for version in 3.14 3.13 3.12; do
    if candidate=$(command -v "python$version"); then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  printf 'Install Python 3.12, 3.13 or 3.14 for the Ansible tools.\n' >&2
  return 1
}

# Older distro builds of pipx remove an environment before rebuilding it.
# Keep the old environment and its exposed links until the command succeeds.
pipx_rebuild() (
  local app=$1
  shift
  local venvs bin man saved venv
  venvs=$(pipx environment --value PIPX_LOCAL_VENVS) || return
  bin=$(pipx environment --value PIPX_BIN_DIR) || return
  man=$(pipx environment --value PIPX_MAN_DIR) || return
  venv="$venvs/$app"
  [[ -d $venv && ! -L $venv ]] || return 1
  saved=$(mktemp -d "$venvs/.workstation-backup.XXXXXXXX") || return
  cp -a -- "$venv" "$saved/venv" || return
  python3 - "$saved/links.json" "$venv" "$bin" "$man" <<'PY' || return
import json
import os
from pathlib import Path
import sys

manifest, environment, binary_dir, man_dir = map(Path, sys.argv[1:])
links = {}
for folder in [binary_dir, *man_dir.glob("man*")]:
    if not folder.is_dir():
        continue
    for path in folder.iterdir():
        if path.is_symlink() and path.resolve().is_relative_to(environment):
            links[str(path)] = os.readlink(path)
manifest.write_text(json.dumps(links))
PY
  if pipx "$@"; then
    rm -rf -- "$saved"
    return
  fi
  mv -T -- "$venv" "$saved/failed" 2>/dev/null || [[ ! -e $venv ]] || {
    printf 'Pipx repair failed. Backup retained at %s\n' "$saved" >&2
    return 1
  }
  if ! mv -T -- "$saved/venv" "$venv"; then
    printf 'Pipx repair failed. Backup retained at %s\n' "$saved" >&2
    return 1
  fi
  python3 - "$saved/links.json" <<'PY' || return
import json
from pathlib import Path
import sys

for name, target in json.loads(Path(sys.argv[1]).read_text()).items():
    path = Path(name)
    if not path.exists() and not path.is_symlink():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(target)
PY
  rm -rf -- "$saved"
  printf 'Restored the previous pipx environment for %s.\n' "$app" >&2
  return 1
)

pipx_app() {
  local python=$1 app=$2 state=$3
  local -a flags=()
  if [[ $app == ansible ]]; then
    flags+=(--include-deps)
  fi
  if [[ $state == missing ]]; then
    pipx install --python "$python" "${flags[@]}" "$app"
    return
  fi

  if [[ $state == migrate* ]]; then
    pipx_rebuild "$app" reinstall --python "$python" "$app" || return
  elif ((repair)); then
    pipx_rebuild "$app" reinstall "$app" || return
  elif ((upgrade)); then
    pipx upgrade --include-injected "$app" || return
  fi

  # Older installs exposed only the top-level package, leaving ansible-core
  # commands such as ansible-playbook out of the user's bin directory.
  if [[ $app == ansible && $state == *unexposed* ]]; then
    pipx_rebuild ansible install --force --include-deps ansible
  fi
}

setup_pipx_apps() {
  local python metadata states app state winrm
  command -v pipx >/dev/null || { printf 'pipx is required. Run the system stage first.\n' >&2; return 1; }
  python=$(select_pipx_python) || return
  metadata=$(pipx list --json) || return
  states=$(python3 -c '
import json, re, sys
venvs = json.load(sys.stdin)["venvs"]
for app in ("ansible", "ansible-lint", "awxkit"):
    if app not in venvs:
        print(app, "missing", "missing")
        continue
    metadata = venvs[app]["metadata"]
    version = metadata.get("python_version") or ""
    state = "installed" if re.search(r"\b3\.(12|13|14)\b", version) else "migrate"
    if app == "ansible" and not metadata["main_package"].get("include_dependencies"):
        state += "-unexposed"
    winrm = "installed" if "pywinrm" in metadata.get("injected_packages", {}) else "missing"
    print(app, state, winrm)
' <<<"$metadata") || return
  local failed=0
  while read -r app state winrm; do
    if pipx_app "$python" "$app" "$state"; then
      if [[ $app == ansible && $winrm == missing ]]; then
        pipx inject ansible pywinrm || failed=1
      fi
    else
      printf 'Could not set up pipx app: %s\n' "$app" >&2
      failed=1
    fi
  done <<<"$states"
  return "$failed"
}

setup_snaps() {
  local name arch installed failed=0
  local -a snaps=()
  arch=$(uname -m) || return
  case "$arch" in x86_64|aarch64) snaps+=(gitkraken) ;; esac
  if [[ $arch == x86_64 ]]; then
    snaps+=(discord)
    if [[ $ID == fedora ]]; then
      snaps+=(slack spotify)
    fi
  fi
  if ! command -v snap >/dev/null || ! timeout 25s snap version >/dev/null; then
    printf 'Snap is unavailable. Run the system stage and check that snapd is running.\n' >&2
    return 1
  fi
  sudo timeout 90s snap wait system seed.loaded || return
  if [[ $ID == fedora ]] && snap_installed steam; then
    snaps+=(steam)
  fi
  if ! package_installed code && snap_installed code; then
    snaps+=(code)
  fi
  installed=$(snap list) || return
  for name in "${snaps[@]}"; do
    if [[ $name == gitkraken && $ID == fedora &&
      $(readlink -f /snap 2>/dev/null) != /var/lib/snapd/snap ]]; then
      printf 'GitKraken requires classic Snap support. Run the system stage to set up /snap.\n' >&2
      failed=1
      continue
    fi
    if awk -v name="$name" '$1 == name { found = 1 } END { exit !found }' <<<"$installed"; then
      if ((upgrade)) && ! sudo snap refresh "$name"; then
        printf 'Snap refresh failed for %s. The installed revision was kept.\n' "$name" >&2
        failed=1
      fi
    elif [[ $name == gitkraken ]]; then
      sudo snap install --classic "$name" || failed=1
    else
      sudo snap install "$name" || failed=1
    fi
  done
  return "$failed"
}

setup_vscode_extensions() {
  local cli=/usr/bin/code name attempt installed failed=0
  local -a extensions=(
    aaron-bond.better-comments
    DavidAnson.vscode-markdownlint
    dbaeumer.vscode-eslint
    eamodio.gitlens
    ecmel.vscode-html-css
    esbenp.prettier-vscode
    golang.Go
    ionutvmi.path-autocomplete
    ms-python.python
    ms-vscode.PowerShell
    PKief.material-icon-theme
    puppet.puppet-vscode
    redhat.vscode-yaml
    Shopify.ruby-lsp
    stylelint.vscode-stylelint
    timonwong.shellcheck
    wholroyd.jinja
    yzhang.markdown-all-in-one
  )
  if [[ ! -x $cli ]]; then
    if snap_installed code; then
      cli=$(command -v snap) || return
    else
      cli=$(command -v code) || {
        printf 'VS Code CLI is missing. Run the system stage first.\n' >&2
        return 1
      }
    fi
  fi
  local -a code_cmd=("$cli") flags=()
  # Target the selected Linux installation even when invoked from WSL.
  export DONT_PROMPT_WSL_INSTALL=1
  if [[ ${cli##*/} == snap ]]; then
    code_cmd+=(run code)
  fi
  installed=$("${code_cmd[@]}" --list-extensions) || return
  for name in "${extensions[@]}"; do
    flags=()
    if grep -Fxiq -- "$name" <<<"$installed"; then
      if ((!upgrade)); then
        continue
      fi
      flags+=(--force)
    fi
    for attempt in 1 2 3; do
      if "${code_cmd[@]}" --install-extension "$name" "${flags[@]}"; then
        break
      fi
      if ((attempt == 3)); then
        printf 'Could not install VS Code extension: %s\n' "$name" >&2
        failed=1
      else
        sleep 3
      fi
    done
  done
  return "$failed"
}

replace_with_backup() {
  local candidate=$1 destination=$2 name backup_dir=
  name=${destination##*/}
  if [[ -e $destination || -L $destination ]]; then
    backup_dir=$(mktemp -d "${destination%/*}/.${name#.}.backup.XXXXXXXX") || return
    if ! mv -T -- "$destination" "$backup_dir/previous"; then
      rmdir -- "$backup_dir"
      return 1
    fi
  fi
  if ! mv -nT -- "$candidate" "$destination" || [[ -e $candidate || -L $candidate ]]; then
    if [[ -n $backup_dir ]]; then
      if mv -nT -- "$backup_dir/previous" "$destination" && [[ ! -e $backup_dir/previous && ! -L $backup_dir/previous ]]; then
        rmdir -- "$backup_dir"
      else
        printf 'Previous files retained at %s\n' "$backup_dir/previous" >&2
      fi
    fi
    return 1
  fi
  if [[ -n $backup_dir ]]; then
    printf 'Saved previous files to %s\n' "$backup_dir/previous"
  fi
}

install_gnome_extension() (
  local id=$1 uuid=$2 shell=$3
  local extensions_dir="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions"
  local dest="$extensions_dir/$uuid" stage path
  if ((!upgrade && !repair)) && [[ -f $dest/metadata.json && -f $dest/extension.js ]] &&
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(d.get("uuid") != sys.argv[2] or sys.argv[3] not in d.get("shell-version", []))' \
      "$dest/metadata.json" "$uuid" "$shell"; then
    printf 'Already installed and compatible: %s\n' "$uuid"
    return 0
  fi

  mkdir -p -- "$extensions_dir" || return
  stage=$(mktemp -d "$extensions_dir/.$uuid.XXXXXXXX") || return
  trap 'rm -rf -- "$stage"' EXIT
  download "https://extensions.gnome.org/extension-info/?pk=$id&shell_version=$shell" "$stage/info.json" || return
  path=$(python3 -c '
import json, sys
data = json.load(open(sys.argv[1]))
path = data.get("download_url", "")
if data.get("uuid") != sys.argv[2] or not path.startswith("/download-extension/"):
    sys.exit("No compatible published version for " + sys.argv[2])
print(path)
' "$stage/info.json" "$uuid") || return
  download "https://extensions.gnome.org$path" "$stage/extension.zip" || return
  python3 - "$stage" "$uuid" "$shell" <<'PY' || return
import json
from pathlib import Path
import sys
from zipfile import ZipFile

stage, uuid, shell = sys.argv[1:]
root = Path(stage)
with ZipFile(root / "extension.zip") as bundle:
    meta = json.loads(bundle.read("metadata.json"))
    if meta.get("uuid") != uuid or shell not in meta.get("shell-version", []):
        sys.exit("GNOME extension metadata does not match the requested UUID and shell")
    if "extension.js" not in bundle.namelist():
        sys.exit("GNOME extension is missing its built JavaScript")
    bundle.extractall(root / "build")
PY
  if [[ -d $stage/build/schemas ]]; then
    glib-compile-schemas --strict "$stage/build/schemas" || return
  fi
  replace_with_backup "$stage/build" "$dest" || return
  printf 'Installed %s. Enable it in GNOME Extensions after logging in again.\n' "$uuid"
)

setup_gnome_extensions() {
  local version major minor failed=0
  if ! command -v gnome-shell >/dev/null; then
    printf 'GNOME Shell is absent. Skipping GNOME extensions.\n'
    return 0
  fi
  version=$(gnome-shell --version) || return
  if [[ ! $version =~ ([0-9]+)\.([0-9]+) ]]; then
    printf 'Could not determine GNOME Shell version: %s\n' "$version" >&2
    return 1
  fi
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  if ((major < 40)); then
    major+=".$minor"
  fi
  install_gnome_extension 1160 dash-to-panel@jderose9.github.com "$major" || failed=1
  install_gnome_extension 28 gTile@vibou "$major" || failed=1
  return "$failed"
}

setup_oh_my_zsh() (
  local dest="$HOME/.oh-my-zsh" stage
  local omz_repair=${FORCE_REINSTALL_OMZ:-$repair} login_shell
  login_shell=$(getent passwd "$(id -un)" | cut -d: -f7) || return
  command -v zsh >/dev/null || { printf 'Install zsh before setting up Oh My Zsh.\n' >&2; return 1; }
  if [[ -f $dest/oh-my-zsh.sh && $omz_repair != 1 ]]; then
    if ((upgrade)); then
      git -C "$dest" pull --ff-only || return
    fi
    return 0
  fi
  if [[ -e $dest || -L $dest ]] && [[ $omz_repair != 1 ]]; then
    printf '%s is incomplete. Run with --repair to replace it safely.\n' "$dest" >&2
    return 1
  fi
  stage=$(mktemp -d "$HOME/.oh-my-zsh.install.XXXXXXXX") || return
  trap 'rm -rf -- "$stage"' EXIT
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$stage/source" || return
  [[ -f $stage/source/oh-my-zsh.sh ]] || return 1
  if [[ -d $dest/custom ]]; then
    cp -a -- "$dest/custom/." "$stage/source/custom/" || return
  fi
  replace_with_backup "$stage/source" "$dest" || return
  if [[ ${login_shell##*/} != zsh ]]; then
    printf 'To switch your login shell, run: chsh -s %s\n' "$(command -v zsh)"
  fi
)

setup_user() {
  export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:/snap/bin:/var/lib/snapd/snap/bin:$PATH"
  if [[ -z $only || $only == pipx ]]; then run_step "Set up Python CLI apps" setup_pipx_apps; fi
  if [[ -z $only || $only == snaps ]]; then run_step "Set up Snap apps" setup_snaps; fi
  if [[ -z $only || $only == vscode ]]; then run_step "Set up VS Code extensions" setup_vscode_extensions; fi
  if [[ -z $only || $only == gnome ]]; then run_step "Set up GNOME extensions" setup_gnome_extensions; fi
  if [[ -z $only || $only == zsh ]]; then run_step "Set up Oh My Zsh" setup_oh_my_zsh; fi
  if [[ -z $only || $only == dotfiles ]]; then run_step "Stow dotfiles" bash "$repo_dir/dots/stowit.sh"; fi
}

main() {
  local arg
  for arg; do
    case "$arg" in
      --system|--user)
        [[ $mode == all ]] || die "Choose one of --system and --user."
        mode=${arg#--}
        ;;
      --upgrade) upgrade=1 ;;
      --repair) repair=1 ;;
      --only=*) only=${arg#--only=}; [[ -n $only ]] || die "Specify a component after --only=." ;;
      --help|-h) usage; return 0 ;;
      *) die "Unknown option: $arg" ;;
    esac
  done
  [[ $repair == 0 || $repair == 1 ]] || die "FORCE_REINSTALL must be 0 or 1."
  case "$only" in
    '') ;;
    pipx|snaps|vscode|gnome|zsh|dotfiles) [[ $mode == user ]] || die "--only requires --user." ;;
    *) die "Unknown user component: $only" ;;
  esac

  if ((EUID == 0)); then
    [[ $mode != user ]] || die "Run the user stage as your normal user."
    mode=system
  fi
  [[ -r /etc/os-release ]] || die "Could not read /etc/os-release."
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}:${VERSION_ID:-}" in
    ubuntu:24.04|ubuntu:26.04|ubuntu:26.10|fedora:44|fedora:45) ;;
    *) die "Unsupported system: ${PRETTY_NAME:-unknown}. See the README for supported releases." ;;
  esac
  if [[ $ID == fedora && -e /run/ostree-booted && $mode != user ]]; then
    die "Fedora Atomic desktops need a different system package workflow."
  fi
  log "Detected $PRETTY_NAME"

  if [[ $mode != system && ( -z $only || $only == dotfiles ) && ! -f $repo_dir/dots/stowit.sh ]]; then
    die "The user stage needs the repository's dots directory. Clone the repository first."
  fi

  if [[ $mode == system && $EUID == 0 ]]; then
    case "$ID" in
      ubuntu) run_step "Install Ubuntu system packages" system_ubuntu ;;
      fedora) run_step "Install Fedora system packages" system_fedora ;;
    esac
  else
    if [[ $mode != user ]]; then
      local -a system_args=(--system)
      if ((upgrade)); then system_args+=(--upgrade); fi
      # Copy just the reviewed script into a root-owned location before it
      # runs, so subsequent edits to the checkout cannot change the root stage.
      # shellcheck disable=SC2016
      run_step "Install system packages" sudo bash -c '
        set -eu
        stage=$(mktemp -d)
        trap "rm -rf -- \"\$stage\"" EXIT
        install -m 0600 "$1" "$stage/install.sh"
        shift
        bash "$stage/install.sh" "$@"
      ' bash "$script_path" "${system_args[@]}"
    fi
    if [[ $mode != system ]]; then
      setup_user
    fi
  fi
  finish
}

main "$@"
