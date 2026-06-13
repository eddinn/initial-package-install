#!/usr/bin/env bash
set -euo pipefail

if ! command -v zsh >/dev/null 2>&1; then
  printf '%s\n' "zsh is not installed. Re-run ./initial-package-install.sh first." >&2
  exit 1
fi

printf '%s\n' "Installing/updating Oh My Zsh"
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

if [[ -d "${HOME}/.oh-my-zsh" ]]; then
  ZSH="${HOME}/.oh-my-zsh" zsh -ic 'omz update' || true
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)" || printf '%s\n' "Could not change default shell automatically. Run: chsh -s $(command -v zsh)"
fi
