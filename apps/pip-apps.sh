#!/usr/bin/env bash

# Define Python3 Pip packages to install
pip_packages=(
 setuptools
 wheel
 ansible
 ansible-lint
 ansible-tower-cli
 pywinrm
 testresources
)

# Install Python3 pip packages
printf -- '%s\n' "Upgrading pip and installing Python3 packages"
# First, upgrade pip to latest version
sudo -H pip3 install pip --upgrade
# Install packages to user space
pip3 install --user "${pip_packages[@]}"
