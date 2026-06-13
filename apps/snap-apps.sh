#!/usr/bin/env bash
set -euo pipefail

classic_snaps=(
  code
  gitkraken
  slack
)

strict_snaps=(
  discord
  spotify
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

printf '%s\n' "Installing/updating classic snaps"
for snap_name in "${classic_snaps[@]}"; do
  install_or_refresh_snap "$snap_name" --classic
done

printf '%s\n' "Installing/updating strict snaps"
for snap_name in "${strict_snaps[@]}"; do
  install_or_refresh_snap "$snap_name"
done
