export PATH="$PATH:/home/fnord/.dotnet/tools"
export PATH="$PATH:/home/fnord/.lmstudio/bin"
export PATH=/usr/local/cuda-12.9/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.9/lib64:$LD_LIBRARY_PATH
export PATH=/home/fnord/.opencode/bin:$PATH

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH=$PATH:/usr/local/go/bin

export GCM_CREDENTIAL_STORE="gpg"
export GPG_TTY=$(tty)
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

. "$HOME/.local/bin/env"
