#!/usr/bin/env bash

# Install gnome extensions
echo -e '\nInstalling extensions for VS Code'

echo -e '\nInstalling Dash-to-Panel'
git clone https://github.com/home-sweet-gnome/dash-to-panel.git
(
  cd ~/.local/share/gnome-shell/extensions/dash-to-panel || echo "Can't change directory"; exit 1
  make install
  cd -
  rm -Rf dash-to-panel
)

echo -e '\nInstalling gTile'
git clone https://github.com/gTile/gTile.git ~/.local/share/gnome-shell/extensions/gTile@vibou

echo -e '\nInstalling Panel-OSD'
git clone git://gitlab.com/jenslody/gnome-shell-extension-panel-osd.git ~/.local/share/gnome-shell/extensions/panel-osd
(
  cd ~/.local/share/gnome-shell/extensions/panel-osd || echo "Can't change directory"; exit 1
  ./autogen.sh && make local-install
  cd -
)

echo -e '\nInstalling Touchpad Indicator'
git clone --depth=1 https://github.com/user501254/TouchpadIndicator.git
mv TouchpadIndicator/ ~/.local/share/gnome-shell/extensions/touchpad-indicator@orangeshirt

echo -e '\nFinished installing Gnome extensions\n'
