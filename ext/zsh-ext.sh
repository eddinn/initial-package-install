#!/usr/bin/env bash

printf -- '%s\n' "Enable zsh and install the Oh-My-Zsh extension"
chsh -s "$(command -v zsh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
