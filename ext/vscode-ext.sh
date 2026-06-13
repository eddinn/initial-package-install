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

failures=()

install_extension() {
  local extension=${1:?No VS Code extension supplied}
  local attempt

  for attempt in 1 2 3; do
    printf '%s\n' "Installing/updating VS Code extension (${attempt}/3): ${extension}"
    if code --install-extension "$extension" --force; then
      return 0
    fi

    sleep 5
  done

  failures+=("${extension}")
  printf '%s\n' "WARNING: failed to install VS Code extension after retries: ${extension}" >&2
}

printf '%s\n' "Installing/updating VS Code extensions"
for extension in "${vscode_extensions[@]}"; do
  install_extension "$extension"
done

if ((${#failures[@]} > 0)); then
  printf '\n%s\n' "VS Code extension warnings:"
  printf '  - %s\n' "${failures[@]}"
fi

printf '%s\n' "Finished installing VS Code extensions"
