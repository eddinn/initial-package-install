#!/usr/bin/env bash

#Install the Qogir theme
printf -- '%s\n' "Installing the Qogir theme"
git clone https://github.com/vinceliuice/Qogir-theme.git
(
  cd Qogir-theme || echo "Can't change directory"; exit 1
  # Install to ~/.themes
  ./install.sh
  # Also install globally for GDM for a good measure
  sudo ./install.sh -g
  cd - || echo "Can't change directory"; exit 1
  rm -Rf Qogir-theme
)
