#!/usr/bin/env bash
set -euo pipefail

if ! command -v code >/dev/null 2>&1; then
  printf '%s\n' "VS Code CLI ('code') was not found. Install VS Code first, then re-run this script." >&2
  exit 1
fi

vscode_extensions=(
  766b.go-outliner
  aaron-bond.better-comments
  DavidAnson.vscode-markdownlint
  dbaeumer.vscode-eslint
  donjayamanne.githistory
  eamodio.gitlens
  ecmel.vscode-html-css
  esbenp.prettier-vscode
  formulahendry.code-runner
  GitLab.gitlab-workflow
  golang.Go
  ionutvmi.path-autocomplete
  magicstack.MagicPython
  michelemelluso.gitignore
  mikestead.dotenv
  ms-python.python
  ms-python.vscode-pylance
  ms-vscode.PowerShell
  PKief.material-icon-theme
  pranaygp.vscode-css-peek
  puppet.puppet-vscode
  rebornix.Ruby
  redhat.vscode-yaml
  rogalmic.bash-debug
  samverschueren.final-newline
  shd101wyy.markdown-preview-enhanced
  SirTori.indenticator
  stylelint.vscode-stylelint
  timonwong.shellcheck
  vincaslt.highlight-matching-tag
  VisualStudioExptTeam.vscodeintellicode
  vscode-icons-team.vscode-icons
  wholroyd.jinja
  yzhang.markdown-all-in-one
)

printf '%s\n' "Installing/updating VS Code extensions"
for extension in "${vscode_extensions[@]}"; do
  code --install-extension "$extension" --force
done

printf '%s\n' "Finished installing VS Code extensions"
