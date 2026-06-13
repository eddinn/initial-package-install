#!/usr/bin/env bash
set -euo pipefail

base=(
  bash
  zsh
)

user_only=(
  git
  bin
)

stow_package() {
  local target=${1:?No target directory supplied}
  local package=${2:?No stow package supplied}

  stow -v -R -t "$target" "$package"
}

printf '\n%s\n' "Stowing dotfiles for user: $(whoami)"

for package in "${base[@]}"; do
  stow_package "$HOME" "$package"
done

if [[ ${EUID} -ne 0 ]]; then
  for package in "${user_only[@]}"; do
    stow_package "$HOME" "$package"
  done
fi

printf '\n%s\n' "All done!"
