#!/usr/bin/env bash
set -euo pipefail
exec bash "$(dirname -- "$(realpath -e -- "${BASH_SOURCE[0]}")")/initial-package-install.sh" --user "$@"
