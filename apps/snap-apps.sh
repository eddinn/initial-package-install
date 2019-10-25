#!/usr/bin/env bash

# Define Snap packages to install
snap_packages=(
 discord
 gitkraken
 spotify
)

# Install user snap packages
printf -- '%s\n' "Installing VSCode and Slack with --classic"
sudo snap install code --classic
sudo snap install slack --classic
printf -- '%s\n' "Installing Snap packages"
# Install the rest of the snap packages
for snaps in "${snap_packages[@]}";
do
 sudo snap install "$snaps";
done
