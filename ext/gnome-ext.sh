#!/usr/bin/env bash
set -euo pipefail

extension_dir="${HOME}/.local/share/gnome-shell/extensions"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

install -d "$extension_dir"

clone_or_update() {
  local name=${1:?No extension name supplied}
  local repo=${2:?No repository URL supplied}
  local target=${3:?No target directory supplied}

  printf '%s\n' "Installing/updating ${name}"
  rm -rf "$target"
  git clone --depth=1 "$repo" "$target"
}

printf '%s\n' "Installing/updating GNOME extensions"

clone_or_update "Dash to Panel" https://github.com/home-sweet-gnome/dash-to-panel.git "${tmpdir}/dash-to-panel"
(
  cd "${tmpdir}/dash-to-panel" || { printf '%s\n' "Can't change directory to Dash to Panel source" >&2; exit 1; }
  make install
)

clone_or_update "gTile" https://github.com/gTile/gTile.git "${extension_dir}/gTile@vibou"

clone_or_update "Panel OSD" https://gitlab.com/jenslody/gnome-shell-extension-panel-osd.git "${tmpdir}/panel-osd"
(
  cd "${tmpdir}/panel-osd" || { printf '%s\n' "Can't change directory to Panel OSD source" >&2; exit 1; }
  ./autogen.sh
  make local-install
)

clone_or_update "Touchpad Indicator" https://github.com/user501254/TouchpadIndicator.git "${extension_dir}/touchpad-indicator@orangeshirt"

printf '%s\n' "Finished installing GNOME extensions"
