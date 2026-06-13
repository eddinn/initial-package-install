#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v pipx >/dev/null 2>&1; then
  printf '%s\n' "pipx is required. Re-run ./initial-package-install.sh first, or install pipx manually." >&2
  exit 1
fi

install_or_upgrade() {
  local app=${1:?No pipx app name supplied}
  shift || true

  if pipx list --short 2>/dev/null | awk '{print $1}' | grep -Fxq "$app"; then
    pipx upgrade "$app"
  else
    pipx install "$app" "$@"
  fi
}

printf '%s\n' "Using PATH with ${HOME}/.local/bin for pipx apps"

printf '%s\n' "Installing/upgrading Python CLI tools"
install_or_upgrade ansible
install_or_upgrade ansible-lint
install_or_upgrade awxkit

printf '%s\n' "Adding WinRM support to the Ansible pipx environment"
pipx inject --force ansible pywinrm
