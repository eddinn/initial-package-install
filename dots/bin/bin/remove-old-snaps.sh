#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "Removing disabled snap revisions. Close running snap apps before continuing."

snap list --all | awk '/disabled/{print $1, $3}' |
  while read -r snap_name revision; do
    sudo snap remove "$snap_name" --revision="$revision"
  done
