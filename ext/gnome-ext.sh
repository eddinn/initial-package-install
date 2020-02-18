#!/usr/bin/env bash

# Install gnome extensions
printf -- '%s\n' "Installing extensions for VS Code"

printf -- '%s\n' "Installing Dash-to-Panel"
git clone https://github.com/home-sweet-gnome/dash-to-panel.git
(
  cd ./dash-to-panel || echo "Can't change directory"; exit 1
  make install
  cd - || echo "Can't change directory"; exit 1
)

printf -- '%s\n' "Installing gTile"
git clone https://github.com/gTile/gTile.git ~/.local/share/gnome-shell/extensions/gTile@vibou

printf -- '%s\n' "Installing Panel-OSD"
git clone git://gitlab.com/jenslody/gnome-shell-extension-panel-osd.git ~/.local/share/gnome-shell/extensions/panel-osd
(
  cd ~/.local/share/gnome-shell/extensions/panel-osd || echo "Can't change directory"; exit 1
  ./autogen.sh && make local-install
  cd - || echo "Can't change directory"; exit 1
)

printf -- '%s\n' "Installing Touchpad Indicator"
git clone --depth=1 https://github.com/user501254/TouchpadIndicator.git
mv TouchpadIndicator/ ~/.local/share/gnome-shell/extensions/touchpad-indicator@orangeshirt

printf -- '%s\n' "Finished installing Gnome extensions" '%s\n'
