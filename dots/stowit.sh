#!/usr/bin/env bash
set -euo pipefail

script=$(realpath -e -- "${BASH_SOURCE[0]}")
cd -- "${script%/*}"
command -v stow >/dev/null || { printf 'GNU Stow is required.\n' >&2; exit 1; }

shell_path=${DOTFILES_SHELL:-}
if [[ -z $shell_path ]]; then
  shell_path=$(getent passwd "$(id -un)" | cut -d: -f7)
fi
shell_path=${shell_path:-${SHELL:-}}

packages=()
case "${shell_path##*/}" in
  bash|zsh) packages+=("${shell_path##*/}") ;;
  *) printf 'No supported login shell found. Set DOTFILES_SHELL=bash or zsh to select its dotfiles.\n' ;;
esac
if ((EUID != 0)); then
  packages+=(git bin)
fi
if ((${#packages[@]} == 0)); then
  exit 0
fi

# Preflight the conflicts before touching files in the target directory.
# Only top-level regular files are eligible for automatic backup.
shopt -s dotglob nullglob
targets=()
check_targets() {
  local package=$1 source=$2 target=$3 child
  if [[ -L $target ]]; then
    if [[ $(realpath -m -- "$target") != "$(realpath -m -- "$source")" ]]; then
      printf 'Stow conflict: %s is an existing symlink.\n' "$target" >&2
      return 1
    fi
  elif [[ -d $source && -d $target ]]; then
    for child in "$source"/*; do
      check_targets "$package" "$child" "$target/${child##*/}" || return
    done
  elif [[ -f $source && -f $target && ${source%/*} == "$package" ]]; then
    targets+=("$target")
  elif [[ -e $target ]]; then
    printf 'Stow conflict: %s already exists.\n' "$target" >&2
    return 1
  fi
}
for package in "${packages[@]}"; do
  for source in "$package"/*; do
    check_targets "$package" "$source" "$HOME/${source##*/}"
  done
done

if ((${#targets[@]} == 0)); then
  exec stow -v -t "$HOME" "${packages[@]}"
fi

backup=$(mktemp -d "$HOME/.initial-package-install-dotfiles.XXXXXXXX")
moved=()
rollback() {
  local status=$?
  if ((status != 0)); then
    local file
    for file in "${moved[@]}"; do
      if [[ ! -e $file && ! -L $file ]]; then
        mv -T -- "$backup/${file##*/}" "$file" || true
      fi
    done
    rmdir -- "$backup" 2>/dev/null || printf 'Remaining dotfile backups: %s\n' "$backup" >&2
  fi
}
trap rollback EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for target in "${targets[@]}"; do
  mv -T -- "$target" "$backup/${target##*/}"
  moved+=("$target")
done
stow --simulate -t "$HOME" "${packages[@]}"
stow -v -t "$HOME" "${packages[@]}"
printf 'Saved original dotfiles to %s\n' "$backup"
