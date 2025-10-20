if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[ -s "/home/fnord/.bun/_bun" ] && source "/home/fnord/.bun/_bun"

alias ls='ls --color=auto'
export LS_COLORS="$(vivid generate catppuccin-mocha)"

# Fix GPG and Git Credential Manager in tmux
export GPG_TTY=$(tty)

# Refresh GPG agent info if needed
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

# Update GPG_TTY before each command (critical for tmux)
preexec() {
  export GPG_TTY=$(tty)
  gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
}

if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && [[ -z "$SSH_NO_TMUX" ]]; then
  exec tmux new-session -A -s ssh || tmux new-session -s ssh
fi
