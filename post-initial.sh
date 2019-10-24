#!/usr/bin/env bash

# Install snap packages
echo -e '\nInstalling snaps and python pip packages'
for app in ./apps/*.sh;
do
 bash ./apps/"$app";
done

# Install extensions for apps
echo -e '\nInstalling apps extensions'
for exts in ./ext/*-ext.sh;
do
 bash ./ext/"$exts";
done

# Stow all the dotfiles
echo -e '\nStowing the dotfiles into' "$HOME"
cd ./dots || echo "Can't change directory"; exit 1
bash ./stowit.sh

echo -e '\n##########'
echo -e '\n All done, workspace setup complete!'
