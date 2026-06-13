#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "Cleaning up APT packages"
sudo apt-get -f install
sudo apt-get --purge autoremove -y
sudo apt-get autoclean -y
sudo apt-get clean
