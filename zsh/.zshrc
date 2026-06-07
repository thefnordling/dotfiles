if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

alias ls='eza --color=auto --icons --git --group-directories-first'
export LS_COLORS="$(vivid generate catppuccin-mocha)"

# GPG_TTY for tmux compatibility
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

# Update GPG_TTY before each command (critical for tmux)
preexec() {
  export GPG_TTY=$(tty)
  gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
}

if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && [[ -z "$SSH_NO_TMUX" ]] && [[ "$TERM" != "screen"* ]]; then
  exec tmux new-session -A -s ssh || tmux new-session -s ssh
fi

# Prefer CUDA 13.0 in this user shell
export PATH=/usr/local/cuda-13.0/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:${LD_LIBRARY_PATH}

# KDB-X Installation Configuration - Thu Mar 12 07:40:32 AM PDT 2026
export QHOME=~/q
export PATH="$QHOME/l64:$PATH"
alias q="taskset -c 0-23 rlwrap -r q"
# End KDB-X Installation Configuration
