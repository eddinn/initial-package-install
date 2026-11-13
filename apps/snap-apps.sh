#!/usr/bin/env bash
set -euo pipefail
script=$(realpath -e -- "${BASH_SOURCE[0]}")
exec bash "${script%/*}/../initial-package-install.sh" --user --only=snaps "$@"
