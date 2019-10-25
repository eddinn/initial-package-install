#!/usr/bin/env bash

# Install snap packages
printf -- '%s\n' "Installing snaps and python pip packages"
for app in ./apps/*-apps.sh;
do
 bash "$app";
done

# Install extensions for apps
printf -- '%s\n' "Installing apps extensions"
for exts in ./ext/*-ext.sh;
do
 bash "$exts";
done

# Stow all the dotfiles
printf -- '%s\n' "Stowing the dotfiles into $HOME"
(
  cd ./dots || echo "Can't change directory"; exit 1
  bash ./stowit.sh
)

printf -- '%s\n' "##########"
printf -- '%s\n' "All done, workspace setup complete!"
