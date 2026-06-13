#!/usr/bin/env bash
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

install_qogir_dependencies() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y libglib2.0-dev-bin
  fi
}

printf '%s\n' "Installing/updating the Qogir theme"
git clone --depth=1 https://github.com/vinceliuice/Qogir-theme.git "${tmpdir}/Qogir-theme"
(
  cd "${tmpdir}/Qogir-theme" || { printf '%s\n' "Can't change directory to Qogir theme source" >&2; exit 1; }
  install_qogir_dependencies
  ./install.sh
  sudo ./install.sh -g
)
