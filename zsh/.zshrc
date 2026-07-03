if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source secrets (not tracked in dotfiles)
[ -f "$HOME/.config/secrets/environment" ] && source "$HOME/.config/secrets/environment"

# macOS-specific config (stowed via darwin/ package, absent on Linux)
[ -f "$HOME/.config/zsh/darwin" ] && source "$HOME/.config/zsh/darwin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

[ -f "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme" ] && source "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

alias ls='eza --color=auto --icons --git --group-directories-first'

# fd: Debian ships as fdfind, Homebrew as fd
if command -v fdfind &>/dev/null; then
  alias fd='fdfind -HI'
else
  alias fd='fd -HI'
fi

export LS_COLORS="$(vivid generate catppuccin-mocha)"

# GPG_TTY for tmux compatibility
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

# Update GPG_TTY before each command (critical for tmux)
preexec() {
  export GPG_TTY=$(tty)
  gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
}

# Linux-only: CUDA paths
case "$(uname -s)" in
  Linux)
    export PATH=/usr/local/cuda-13.0/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:${LD_LIBRARY_PATH}
    ;;
esac

# KDB-X Installation Configuration - Thu Mar 12 07:40:32 AM PDT 2026
export QHOME=~/q
export PATH="$QHOME/l64:$PATH"

case "$(uname -s)" in
  Linux) alias q="taskset -c 0-23 rlwrap -r q" ;;
  *) alias q="rlwrap -r q" ;;
esac
# End KDB-X Installation Configuration

if [[ -z "$TMUX" ]] && [[ -z "$SSH_NO_TMUX" ]] && [[ "$TERM" != "screen"* ]] && [[ -t 0 ]]; then
  if [[ -n "$SSH_CONNECTION" ]]; then
    tmux new-session -A -s ssh
  else
    tmux new-session
  fi
fi
