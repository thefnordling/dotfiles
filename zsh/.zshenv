if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

export PATH="$PATH:/home/fnord/.dotnet/tools"
export PATH=/usr/local/cuda-12.9/bin:$PATH
export PATH=/home/fnord/.opencode/bin:$PATH
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"

export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
