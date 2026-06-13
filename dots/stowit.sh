#!/usr/bin/env bash
set -euo pipefail

user_only=(
  git
  bin
)

detect_shell_package() {
  local shell_path=${SHELL:-}

  if [[ -z "$shell_path" ]] && command -v getent >/dev/null 2>&1; then
    shell_path=$(getent passwd "$(id -un)" | awk -F: '{print $7}')
  fi

  case "${shell_path##*/}" in
    bash) printf '%s\n' bash ;;
    zsh) printf '%s\n' zsh ;;
    *) return 1 ;;
  esac
}

stow_package() {
  local target=${1:?No target directory supplied}
  local package=${2:?No stow package supplied}

  stow -v -R -t "$target" "$package"
}

printf '\n%s\n' "Stowing dotfiles for user: $(whoami)"

if shell_package=$(detect_shell_package); then
  printf '%s\n' "Detected shell package: ${shell_package}"
  stow_package "$HOME" "$shell_package"
else
  printf '%s\n' "No supported shell package detected; skipping shell dotfiles" >&2
fi

if [[ ${EUID} -ne 0 ]]; then
  for package in "${user_only[@]}"; do
    stow_package "$HOME" "$package"
  done
fi

printf '\n%s\n' "All done!"
