#!/usr/bin/env bash
set -euo pipefail

run_scripts() {
  local label=$1
  local pattern=$2
  local script

  shopt -s nullglob
  local scripts=( $pattern )
  shopt -u nullglob

  if ((${#scripts[@]} == 0)); then
    printf '%s\n' "No ${label} scripts found for pattern: ${pattern}"
    return 0
  fi

  printf '\n%s\n' "==> Running ${label} scripts"
  for script in "${scripts[@]}"; do
    printf '%s\n' "Running ${script}"
    bash "$script"
  done
}

run_scripts "application" "./apps/*-apps.sh"
run_scripts "extension" "./ext/*-ext.sh"

printf '\n%s\n' "==> Stowing dotfiles into ${HOME}"
(
  cd ./dots || { printf '%s\n' "Can't change directory to ./dots" >&2; exit 1; }
  bash ./stowit.sh
)

printf '\n%s\n' "All done, workspace setup complete!"
