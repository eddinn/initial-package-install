#!/usr/bin/env bash
set -euo pipefail

FORCE_REINSTALL_OMZ="${FORCE_REINSTALL_OMZ:-0}"
omz_dir="${HOME}/.oh-my-zsh"

if ! command -v zsh >/dev/null 2>&1; then
  printf '%s\n' "zsh is not installed. Re-run ./initial-package-install.sh first." >&2
  exit 1
fi

clone_oh_my_zsh() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${tmpdir}/oh-my-zsh"
  rm -rf "$omz_dir"
  mv "${tmpdir}/oh-my-zsh" "$omz_dir"
}

printf '%s\n' "Installing/updating Oh My Zsh"
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

if [[ -d "$omz_dir" && "$FORCE_REINSTALL_OMZ" != "1" ]]; then
  printf '%s\n' "Oh My Zsh is already installed; updating in place"
  git -C "$omz_dir" pull --ff-only || printf '%s\n' "Could not update Oh My Zsh right now; continuing." >&2
elif [[ -d "$omz_dir" && "$FORCE_REINSTALL_OMZ" == "1" ]]; then
  printf '%s\n' "Force reinstalling Oh My Zsh because FORCE_REINSTALL_OMZ=1"
  clone_oh_my_zsh || printf '%s\n' "Could not reinstall Oh My Zsh right now; keeping existing install if present." >&2
else
  clone_oh_my_zsh || printf '%s\n' "Could not install Oh My Zsh right now; continuing." >&2
fi

if [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
  printf '%s\n' "Default shell is not zsh. Change it manually with: chsh -s $(command -v zsh)"
fi
