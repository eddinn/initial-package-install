#!/usr/bin/env bash
set -euo pipefail

extension_dir="${HOME}/.local/share/gnome-shell/extensions"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

failures=()
install -d "$extension_dir"

clone_or_replace() {
  local name=${1:?No extension name supplied}
  local repo=${2:?No repository URL supplied}
  local target=${3:?No target directory supplied}
  local depth=${4:-full}

  printf '%s\n' "Installing/updating ${name}"
  rm -rf "$target"

  if [[ "$depth" == "shallow" ]]; then
    git clone --depth=1 "$repo" "$target"
  else
    git clone "$repo" "$target"
  fi
}

run_extension_step() {
  local name=${1:?No extension name supplied}
  shift

  if "$@"; then
    return 0
  fi

  failures+=("${name}")
  printf '%s\n' "WARNING: ${name} failed; continuing" >&2
}

install_dash_to_panel() {
  clone_or_replace "Dash to Panel" https://github.com/home-sweet-gnome/dash-to-panel.git "${tmpdir}/dash-to-panel" full
  (
    cd "${tmpdir}/dash-to-panel" || { printf '%s\n' "Can't change directory to Dash to Panel source" >&2; exit 1; }
    make install
  )
}

install_gtile() {
  clone_or_replace "gTile" https://github.com/gTile/gTile.git "${extension_dir}/gTile@vibou" shallow
}

install_touchpad_indicator() {
  clone_or_replace "Touchpad Indicator" https://github.com/user501254/TouchpadIndicator.git "${extension_dir}/touchpad-indicator@orangeshirt" shallow
}

printf '%s\n' "Installing/updating GNOME extensions"
run_extension_step "Dash to Panel" install_dash_to_panel
run_extension_step "gTile" install_gtile
printf '%s\n' "Skipping Panel OSD: its autogen-based build is broken on this Ubuntu setup"
run_extension_step "Touchpad Indicator" install_touchpad_indicator

if ((${#failures[@]} > 0)); then
  printf '\n%s\n' "GNOME extension warnings:"
  printf '  - %s\n' "${failures[@]}"
fi

printf '%s\n' "Finished installing GNOME extensions"
