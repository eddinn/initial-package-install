#!/usr/bin/env bash
set -euo pipefail

failures=()

user_shell() {
  basename "${SHELL:-unknown}"
}

export PATH="${HOME}/bin:${HOME}/.local/bin:${HOME}/.npm-global/bin:${PATH}"
printf '%s\n' "Detected user shell: $(user_shell)"

run_scripts() {
  local label=$1
  local pattern=$2
  local script
  local scripts=()

  shopt -s nullglob
  scripts=( $pattern )
  shopt -u nullglob

  if ((${#scripts[@]} == 0)); then
    printf '%s\n' "No ${label} scripts found for pattern: ${pattern}"
    return 0
  fi

  printf '\n%s\n' "==> Running ${label} scripts"
  for script in "${scripts[@]}"; do
    printf '%s\n' "Running ${script}"
    if bash "$script"; then
      continue
    fi

    failures+=("${script}")
    printf '%s\n' "WARNING: ${script} failed; continuing" >&2
  done
}

run_scripts "application" "./apps/*-apps.sh"
run_scripts "extension" "./ext/*-ext.sh"

printf '\n%s\n' "==> Stowing dotfiles into ${HOME}"
if ! (
  cd ./dots || { printf '%s\n' "Can't change directory to ./dots" >&2; exit 1; }
  bash ./stowit.sh
); then
  failures+=("./dots/stowit.sh")
fi

if ((${#failures[@]} > 0)); then
  printf '\n%s\n' "Completed with warnings. Failed steps:"
  printf '  - %s\n' "${failures[@]}"
  exit 0
fi

printf '\n%s\n' "All done, workspace setup complete!"
