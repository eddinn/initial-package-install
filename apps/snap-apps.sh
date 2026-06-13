#!/usr/bin/env bash
set -euo pipefail

classic_snaps=(
  gitkraken
)

strict_snaps=(
  discord
  slack
  spotify
  steam
)

install_or_refresh_snap() {
  local snap_name=${1:?No snap name supplied}
  shift || true

  if snap list "$snap_name" >/dev/null 2>&1; then
    sudo snap refresh "$snap_name"
  else
    sudo snap install "$snap_name" "$@"
  fi
}

install_code_fallback() {
  if command -v code >/dev/null 2>&1; then
    printf '%s\n' "VS Code is already installed; skipping code snap fallback"
    return 0
  fi

  printf '%s\n' "VS Code was not found; installing code snap fallback"
  install_or_refresh_snap code --classic
}

printf '%s\n' "Installing/updating classic snaps"
for snap_name in "${classic_snaps[@]}"; do
  install_or_refresh_snap "$snap_name" --classic
done

install_code_fallback

printf '%s\n' "Installing/updating strict snaps"
for snap_name in "${strict_snaps[@]}"; do
  install_or_refresh_snap "$snap_name"
done
