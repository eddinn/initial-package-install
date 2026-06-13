export ZSH="${HOME}/.oh-my-zsh"
ZSH_THEME="agnoster"
HISTFILE="${HOME}/.zsh_history"

plugins=(
  git
  docker
  docker-compose
  django
  npm
  pip
  pyenv
  python
  rsync
  sudo
  systemd
  ubuntu
  virtualenv
)

if [[ -r "${ZSH}/oh-my-zsh.sh" ]]; then
  source "${ZSH}/oh-my-zsh.sh"
fi

if [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

export GOPATH="${HOME}/Prog/go"
export PATH="${HOME}/bin:${HOME}/.local/bin:${HOME}/.npm-global/bin:${PATH}"

# system aliases
alias pef="ps -ef"
alias paux="ps aux"
alias free="free -m"
alias cls="clear"

# Shell history
alias h="history"

# ls aliases
alias la="ls -lAtr --color=auto"

# project shortcuts
alias cdp="cd ~/Prog && ls -lAtr"

# directory shortcuts
alias cd..="cd .."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias md="mkdir -p"
alias rd="rmdir"

# apt aliases
alias apt-upgrade="sudo apt update && sudo apt dist-upgrade && apt-cleanup.sh"

# git helpers
alias gitp="git pull"
alias gits="git status"
alias gitd="git diff"

gitcb() {
  git checkout -b "$1"
}

gitc() {
  git checkout "$1"
}

# Usage: gitf "commit message" branch-name
gitf() {
  if (($# != 2)); then
    printf '%s\n' 'Usage: gitf "commit message" branch-name' >&2
    return 1
  fi

  git add . && git commit -m "$1" && git push origin "$2"
}
