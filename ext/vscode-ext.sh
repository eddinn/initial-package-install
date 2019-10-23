#!/usr/bin/env bash

# define the extensions to install
vscext=(
  766b.go-outliner
  aaron-bond.better-comments
  balazs4.gitlab-pipeline-monitor
  CoenraadS.bracket-pair-colorizer
  DavidAnson.vscode-markdownlint
  dbaeumer.vscode-eslint
  donjayamanne.githistory
  donjayamanne.python-extension-pack
  eamodio.gitlens
  ecmel.vscode-html-css
  esbenp.prettier-vscode
  fatihacet.gitlab-workflow
  formulahendry.code-runner
  formulahendry.terminal
  HookyQR.beautify
  ionutvmi.path-autocomplete
  jpogran.puppet-vscode
  KevinRose.vsc-python-indent
  logerfo.gitlab-notifications
  magicstack.MagicPython
  mikestead.dotenv
  ms-python.python
  ms-vscode.Go
  ms-vscode.powershell
  msjsdiag.debugger-for-chrome
  msyrus.go-doc
  neverik.go-critic
  PKief.material-icon-theme
  pranaygp.vscode-css-peek
  premparihar.gotestexplorer
  rebornix.ruby
  redhat.vscode-yaml
  rogalmic.bash-debug
  samverschueren.final-newline
  shd101wyy.markdown-preview-enhanced
  shinnn.stylelint
  SirTori.indenticator
  steoates.autoimport
  timonwong.shellcheck
  VisualStudioExptTeam.vscodeintellicode
  vscode-icons-team.vscode-icons
  wholroyd.jinja
  windmilleng.vscode-go-autotest
  yzhang.markdown-all-in-one
)

# Install the extensions
echo -e '\nInstalling extensions for VSCode'
for ext in "${vscext[@]}";
do
 code --install-extension "$ext";
done

echo -e '\nFinished installing VSCode extensions\n'
