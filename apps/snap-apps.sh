#!/usr/bin/env bash

# Define Snap packages to install
snap_packages=(
 discord
 gitkraken
 spotify
)

# Install user snap packages
echo -e '\nInstalling VSCode and Slack with --classic'
sudo snap install code --classic
sudo snap install slack --classic
echo -e '\nInstalling Snap packages'
# Install the rest of the snap packages
for snaps in "${snap_packages[@]}";
do
 sudo snap install "$snaps";
done
