#!/usr/bin/env bash
set -euo pipefail

# =============== UI helpers ===============
emoji_info="ℹ️"
emoji_ok="✅"
emoji_warn="⚠️"
emoji_run="🚀"
emoji_key="🔑"
emoji_box="📦"
emoji_edit="📝"
emoji_link="🔗"

log() { printf "%b %s\n" "$emoji_info" "$*"; }
ok() { printf "%b %s\n" "$emoji_ok" "$*"; }
warn() { printf "%b %s\n" "$emoji_warn" "$*"; }
run() { printf "%b %s\n" "$emoji_run" "$*"; }

die() {
    printf "%b %s\n" "💥" "$*" >&2
    exit 1
}

trap 'die "An error occurred. Check the output above."' ERR

# =============== Sanity checks ===============
if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        die "This script needs root privileges for apt operations. Please run as root or install sudo."
    fi
else
    SUDO=""
fi

# =============== Install packages ===============
run "Updating apt and installing dependencies: dotnet-sdk-8.0, git, gpg, pass $emoji_box"
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -y
$SUDO apt-get install -y dotnet-sdk-8.0 git gpg pass
ok "Packages installed"

# =============== Configure Git to use GCM with GPG-backed pass ===============
run "Configuring Git credential store to 'gpg' via pass $emoji_link"
git config --global credential.credentialStore gpg
ok "git config set: credential.credentialStore=gpg"

# =============== Ensure we have a GPG key (interactive if needed) ===============
have_secret_keys=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1=="sec" {print $0; exit 0} END{exit NR?0:1}' || true)

if [[ -z "${have_secret_keys}" ]]; then
    warn "No existing GPG secret key detected."
    echo
    echo "  $emoji_key You’ll be guided through GPG key creation now (interactive)."
    echo "  Choose modern defaults; a passphrase is recommended."
    echo
    gpg --full-generate-key
    ok "GPG key generated"
else
    ok "Existing GPG secret key detected"
fi

# =============== Extract primary key fingerprint ===============
run "Extracting primary GPG key fingerprint $emoji_key"
PRIMARY_KEY_FINGERPRINT="$(
    gpg --list-keys --fingerprint --with-colons |
        awk -F: '/^pub:/ {in_pub=1; next} in_pub && /^fpr:/ {print $10; exit}'
)"
[[ -n "${PRIMARY_KEY_FINGERPRINT}" ]] || die "Could not determine primary key fingerprint."
ok "Primary key fingerprint: ${PRIMARY_KEY_FINGERPRINT}"

# =============== Initialize pass with primary fingerprint ===============
run "Initializing pass with your primary key fingerprint"
pass init "${PRIMARY_KEY_FINGERPRINT}"
ok "pass is initialized with ${PRIMARY_KEY_FINGERPRINT}"

# =============== Install Git Credential Manager (dotnet tool) ===============
run "Installing Git Credential Manager (dotnet global tool)"
# Make sure current shell can find dotnet global tools right away
export PATH="$PATH:$HOME/.dotnet/tools"
dotnet tool install -g git-credential-manager >/dev/null 2>&1 || {
    # If already installed, update quietly
    dotnet tool update -g git-credential-manager
}
ok "Git Credential Manager installed/updated"

# =============== Persist environment to ~/.profile ===============
run "Persisting environment to \$HOME/.profile $emoji_edit"
touch "$HOME/.profile"

append_line() {
    local line="$1"
    local file="$HOME/.profile"
    # Exact-line idempotency
    grep -qxF "$line" "$file" || echo "$line" >>"$file"
}

append_line 'export PATH="$PATH:$HOME/.dotnet/tools"'
append_line 'export GCM_CREDENTIAL_STORE="gpg"'
append_line 'export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt'
ok "Environment exports ensured in ~/.profile"

# =============== Configure GPG_TTY for tmux compatibility ===============
run "Configuring GPG_TTY for tmux compatibility $emoji_edit"
configure_gpg_tty() {
    local rcfile="$1"
    local marker="# GPG_TTY for tmux compatibility"
    
    if [[ ! -f "$rcfile" ]]; then
        touch "$rcfile"
    fi
    
    if ! grep -qF "$marker" "$rcfile" 2>/dev/null; then
        cat >> "$rcfile" << 'EOF'

# GPG_TTY for tmux compatibility
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

# Update GPG_TTY before each command (critical for tmux)
if [[ -n "${ZSH_VERSION-}" ]]; then
    preexec() {
        export GPG_TTY=$(tty)
        gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    }
elif [[ -n "${BASH_VERSION-}" ]]; then
    PROMPT_COMMAND='export GPG_TTY=$(tty); gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1'
fi
EOF
        ok "Added GPG_TTY configuration to $rcfile"
    else
        ok "GPG_TTY already configured in $rcfile"
    fi
}

# Configure for both bash and zsh
configure_gpg_tty "$HOME/.bashrc"
if command -v zsh >/dev/null 2>&1; then
    configure_gpg_tty "$HOME/.zshrc"
fi

# =============== Configure GCM ===============
run "Running 'git-credential-manager configure'"
git-credential-manager configure
ok "Git Credential Manager configured"

# =============== Make zsh source ~/.profile (if zsh present) ===============
if command -v zsh >/dev/null 2>&1; then
    run "Ensuring zsh loads ~/.profile on login"
    ZP="$HOME/.zprofile"
    touch "$ZP"
    # Correct, idempotent line for zsh login shells:
    if ! grep -qxF '[[ -f ~/.profile ]] && source ~/.profile' "$ZP" 2>/dev/null; then
        echo '[[ -f ~/.profile ]] && source ~/.profile' >>"$ZP"
        ok "Added 'source ~/.profile' to ~/.zprofile"
    else
        ok "~/.zprofile already sources ~/.profile"
    fi
else
    warn "zsh not found; skipping zsh integration"
fi

# =============== Source for current shell ===============
if [[ -n "${ZSH_VERSION-}" ]]; then
    run "Reloading environment for current zsh shell"
    # shellcheck source=/dev/null
    source "$HOME/.zprofile"
    ok "zsh environment reloaded"
elif [[ -n "${BASH_VERSION-}" ]]; then
    run "Reloading environment for current bash shell"
    # shellcheck source=/dev/null
    source "$HOME/.profile"
    ok "bash environment reloaded"
else
    warn "Unknown shell; not auto-sourcing. Open a new shell to use the updated environment."
fi

ok "All done! $emoji_ok Your Git + GPG + pass + GCM setup is ready."
