#!/usr/bin/env bash
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '%s\n' "Installing/updating the Qogir theme"
git clone --depth=1 https://github.com/vinceliuice/Qogir-theme.git "${tmpdir}/Qogir-theme"
(
  cd "${tmpdir}/Qogir-theme" || { printf '%s\n' "Can't change directory to Qogir theme source" >&2; exit 1; }
  ./install.sh
  sudo ./install.sh -g
)
