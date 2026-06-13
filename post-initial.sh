#!/usr/bin/env bash
set -euo pipefail

failures=()

detect_user_shell() {
  local shell_name=""

  if [[ -n ${DOTFILES_SHELL:-} ]]; then
    basename "$DOTFILES_SHELL"
    return 0
  fi

  shell_name=$(ps -p "${PPID}" -o comm= 2>/dev/null | awk '{print $1}' | sed 's/^-//') || true
  case "$shell_name" in
    bash|zsh) printf '%s\n' "$shell_name"; return 0 ;;
  esac

  shell_name=$(basename "${SHELL:-}")
  case "$shell_name" in
    bash|zsh) printf '%s\n' "$shell_name"; return 0 ;;
  esac

  if command -v getent >/dev/null 2>&1; then
    shell_name=$(getent passwd "$(id -un)" | awk -F: '{print $7}' | xargs basename 2>/dev/null) || true
    case "$shell_name" in
      bash|zsh) printf '%s\n' "$shell_name"; return 0 ;;
    esac
  fi

  printf '%s\n' "unknown"
}

export PATH="${HOME}/bin:${HOME}/.local/bin:${HOME}/.npm-global/bin:${PATH}"
export FORCE_REINSTALL="${FORCE_REINSTALL:-1}"
export DOTFILES_SHELL="${DOTFILES_SHELL:-$(detect_user_shell)}"

printf '%s\n' "Detected user shell: ${DOTFILES_SHELL}"
printf '%s\n' "Force reinstall/repair mode: ${FORCE_REINSTALL}"

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
