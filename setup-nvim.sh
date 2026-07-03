#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"
is_macos() { [ "$OS" = "Darwin" ]; }
is_linux() { [ "$OS" = "Linux" ]; }

brew_install() {
    local pkg="$1"
    if brew list "$pkg" &>/dev/null 2>&1; then
        echo "  ✓ $pkg already installed"
    else
        echo "  → Installing $pkg..."
        echo y | CI=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install "$pkg"
    fi
}

if [ ! -L "$HOME/.zshrc" ]; then
    echo "ERROR: Shell configuration not found."
    echo "Please run ./setup-shell.sh first to set up your shell environment."
    exit 1
fi

echo "[1] Remove conflicting packages"
if is_linux; then
    sudo apt remove -y vim vim-tiny vi neovim nodejs libnode-dev libnode109 || true
    sudo apt autoremove -y || true
else
    echo "  → No conflicting packages to remove (skip)"
fi

echo "[2] Dev packages"
if is_linux; then
    sudo apt install -y --no-install-recommends git build-essential unzip curl ripgrep fd-find fontconfig make gcc zsh netcat-openbsd shellcheck
else
    if ! xcode-select -p &>/dev/null; then
        echo "  → Xcode Command Line Tools required. Run 'xcode-select --install' then re-run."
        echo "  → Continuing — some tools may be missing."
    fi
    for pkg in ripgrep fd shellcheck fontconfig; do
        brew_install "$pkg"
    done
fi

echo "[3] Detect desktop environment"
if is_macos; then
    IS_DESKTOP=true
    echo "  → macOS desktop detected"
elif [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] || grep -q "Microsoft\|WSL" /proc/version 2>/dev/null; then
    IS_DESKTOP=true
    echo "  → Desktop environment detected"
else
    IS_DESKTOP=false
    echo "  → No graphical desktop detected (headless mode)"
fi

echo "[4] Download Neovim v0.12.2"
if command -v nvim &> /dev/null && nvim --version | grep -q "v0.12.2"; then
    echo "  ✓ Neovim v0.12.2 already installed (skip)"
elif is_macos; then
    brew_install neovim
else
    echo "  → Installing Neovim v0.12.2..."
    curl -fsSLO https://github.com/neovim/neovim/releases/download/v0.12.2/nvim-linux-x86_64.tar.gz
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
    echo "  ✓ Neovim v0.12.2 installed"
fi

echo "[5] Configure vi/vim alternatives"
if is_linux; then
    sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/nvim 100
    sudo update-alternatives --install /usr/bin/vim vim /usr/local/bin/nvim 100
    sudo update-alternatives --set vi /usr/local/bin/nvim
    sudo update-alternatives --set vim /usr/local/bin/nvim
else
    echo "  → Not needed on macOS (use alias if desired)"
fi

echo "[6] Deploy nvim + ghostty configs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_stow_package() {
    local pkg="$1"
    local target="$2"
    if [ ! -d "$SCRIPT_DIR/$pkg" ]; then
        echo "  → No $pkg package in dotfiles (skip)"
        return
    fi
    if [ -L "$HOME/$target" ]; then
        stow -d "$SCRIPT_DIR" -t "$HOME" -R "$pkg"
        echo "  ✓ $pkg config restowed"
    else
        if [ -e "$HOME/$target" ]; then
            local ts
            ts=$(date +%Y%m%d-%H%M%S)
            local backup="$HOME/$target-backup-$ts"
            echo "  → Backing up existing $target to $backup"
            mv "$HOME/$target" "$backup"
        fi
        stow -d "$SCRIPT_DIR" -t "$HOME" "$pkg"
        echo "  ✓ $pkg config stowed"
    fi
}

_stow_package nvim ".config/nvim"
_stow_package ghostty ".config/ghostty"

echo "[7] Clear neovim cache"
NVIM_CACHE_DIRS=(
    "$HOME/.cache/nvim"
    "$HOME/.local/share/nvim"
    "$HOME/.local/state/nvim"
    "$HOME/.config/nvim/plugin"
)
for dir in "${NVIM_CACHE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "  → Cleared $dir"
    fi
done

NVIM_LOCKFILES=(
    "$HOME/.config/nvim/lazy-lock.json"
    "$HOME/.config/nvim/strict-lock.json"
)
for lockfile in "${NVIM_LOCKFILES[@]}"; do
    if [ -f "$lockfile" ]; then
        rm -f "$lockfile"
        echo "  → Removed $lockfile"
    fi
done
echo "  ✓ Neovim cache cleared"

# ---------------------------------------------------------------------------
echo "[8] Desktop extras (optional)"
# ---------------------------------------------------------------------------
if [ "$IS_DESKTOP" = true ]; then
    if is_macos; then
        echo "[8a] Desktop utilities (skip — pbcopy built-in, emoji fonts built-in)"
    else
        echo "[8a] Desktop packages (xclip, emoji fonts)"
        sudo apt install -y --no-install-recommends xclip fonts-noto-color-emoji
    fi

    echo "[8b] Meslo Nerd Font"
    if is_macos; then
        if brew list --cask font-meslo-lg-nerd-font &>/dev/null 2>&1; then
            echo "  ✓ Meslo Nerd Font already installed"
        else
            echo y | CI=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --cask font-meslo-lg-nerd-font
        fi
    elif fc-list | grep -q "MesloLGS NF"; then
        echo "  ✓ Meslo Nerd Font already installed (skip)"
    else
        echo "  → Installing Meslo Nerd Font..."
        tmpdir="$(mktemp -d)"
        (
            cd "$tmpdir"
            curl -fsSLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
            unzip -q Meslo.zip -d Meslo
            mkdir -p "$HOME/.local/share/fonts"
            cp Meslo/*.ttf "$HOME/.local/share/fonts/"
        )
        fc-cache -f
        rm -rf "$tmpdir"
        echo "  ✓ Meslo Nerd Font installed"
    fi

    echo "[8c] Ghostty terminal"
    if command -v ghostty &> /dev/null; then
        echo "  ✓ Ghostty already installed (skip)"
    elif is_macos; then
        echo y | CI=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --cask ghostty
    else
        echo "  → Installing Ghostty..."
        tmpdir="$(mktemp -d)"
        (
            cd "$tmpdir"
            curl -fsSL https://github.com/ghostty-org/ghostty/releases/latest/download/ghostty-linux-x86_64.tar.gz
            tar -xzf ghostty-linux-x86_64.tar.gz
            sudo mv ghostty /usr/local/bin/
        )
        rm -rf "$tmpdir"
        echo "  ✓ Ghostty installed"
    fi
else
    echo "[8a] Skipping desktop packages (headless mode)"
    echo "[8b] Skipping Meslo Nerd Font (headless mode)"
    echo "[8c] Skipping Ghostty (headless mode)"
fi

echo "[9] Go"
if is_macos; then
    if command -v go &>/dev/null; then
        echo "  ✓ Go already installed ($(go version))"
    else
        brew_install go
    fi
else
    GO_VERSION=1.26.4
    if command -v go &> /dev/null && go version | grep -q "go${GO_VERSION}"; then
        echo "  ✓ Go v${GO_VERSION} already installed (skip)"
    else
        echo "  → Installing Go v${GO_VERSION}..."
        sudo apt remove -y golang golang-go golang-1.* || true
        sudo apt autoremove -y || true

        sudo rm -rf /usr/local/go
        curl -fsSLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
        rm "go${GO_VERSION}.linux-amd64.tar.gz"
        echo "  ✓ Go v${GO_VERSION} installed"
    fi
fi

export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin"

if ! command -v go >/dev/null 2>&1; then
    echo "ERROR: Go installation failed"
    exit 1
fi
echo "Go installed: $(go version)"

gopath_bin="$HOME/go/bin"
mkdir -p "$gopath_bin"
if [ ! -x "$gopath_bin/goimports" ]; then
    echo "  → Installing goimports..."
    go install golang.org/x/tools/cmd/goimports@latest
    echo "  ✓ goimports installed"
else
    echo "  ✓ goimports already installed (skip)"
fi

echo "[10] nvm + Node LTS"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"
nvm install --lts
corepack enable || true
npm install -g typescript

if ! command -v node >/dev/null 2>&1; then
    echo "ERROR: Node installation failed"
    exit 1
fi
echo "Node installed: $(node --version)"
echo "npm installed: $(npm --version)"

echo "[11] .NET 10"
if command -v dotnet &> /dev/null && dotnet --list-sdks | grep -q "^10\."; then
    echo "  ✓ .NET 10 SDK already installed (skip)"
elif is_macos; then
    brew_install dotnet
else
    echo "  → Installing .NET 10 SDK..."
    sudo rm -f /usr/share/keyrings/microsoft-prod.gpg /etc/apt/sources.list.d/microsoft-prod.list
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main' | sudo tee /etc/apt/sources.list.d/microsoft-prod.list >/dev/null
    sudo apt update
    sudo apt install -y dotnet-sdk-10.0
    echo "  ✓ .NET 10 SDK installed"
fi

echo "[12] Python 3"
if is_macos; then
    brew_install python3
else
    sudo apt install -y python3 python3-pip python3-venv
fi

echo "[13] Rust for tools"
if ! command -v rustc >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs -o /tmp/rustup.sh
    sh /tmp/rustup.sh -y
fi
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
cargo install stylua taplo-cli || echo "  → cargo installs skipped (will work after nvim first run)"

echo "[14] Verify essentials"
for b in nvim vi vim rg git go node npm dotnet python3 rustc cargo; do
    if command -v "$b" >/dev/null 2>&1; then
        printf '  %-12s: OK\n' "$b"
    else
        printf '  %-12s: MISSING\n' "$b"
    fi
done

echo "Done! Installation complete."
echo ""
echo "Next steps:"
echo "  1. Set terminal font to 'MesloLGS NF'"
echo "  2. Restart your shell or run: source ~/.bashrc  (or ~/.zshrc)"
echo "  3. Run: nvim - Mason will install LSP/DAP servers on first use"
echo ""
