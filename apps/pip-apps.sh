#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"
FORCE_REINSTALL="${FORCE_REINSTALL:-0}"

if ! command -v pipx >/dev/null 2>&1; then
  printf '%s\n' "pipx is required. Re-run ./initial-package-install.sh first, or install pipx manually." >&2
  exit 1
fi

pipx_app_exists() {
  local app=${1:?No pipx app name supplied}
  pipx list --short 2>/dev/null | awk '{print $1}' | grep -Fxq "$app"
}

install_or_repair() {
  local app=${1:?No pipx app name supplied}
  shift || true

  if [[ "$FORCE_REINSTALL" == "1" ]] && pipx_app_exists "$app"; then
    printf '%s\n' "Force reinstalling pipx app: ${app}"
    pipx uninstall "$app" || true
    pipx install "$app" "$@"
    return 0
  fi

  if pipx_app_exists "$app"; then
    pipx upgrade "$app" || pipx reinstall "$app"
  else
    pipx install "$app" "$@"
  fi
}

printf '%s\n' "Using PATH with ${HOME}/.local/bin for pipx apps"
printf '%s\n' "Installing/upgrading Python CLI tools"
install_or_repair ansible
install_or_repair ansible-lint
install_or_repair awxkit

printf '%s\n' "Adding WinRM support to the Ansible pipx environment"
pipx inject --force ansible pywinrm
