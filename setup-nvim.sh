#!/usr/bin/env bash
set -euo pipefail

if [ ! -L "$HOME/.zshrc" ]; then
    echo "ERROR: Shell configuration not found."
    echo "Please run ./setup-shell.sh first to set up your shell environment."
    exit 1
fi

echo "[1] Remove conflicting packages"
sudo apt remove -y vim vim-tiny vi neovim nodejs libnode-dev libnode109 || true
sudo apt autoremove -y || true

echo "[2] Dev packages"
sudo apt install -y --no-install-recommends git build-essential unzip curl ripgrep fd-find fontconfig make gcc zsh netcat-openbsd

echo "[3] Detect desktop environment"
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] || grep -q "Microsoft\|WSL" /proc/version 2>/dev/null; then
    IS_DESKTOP=true
    echo "  → Desktop environment detected"
else
    IS_DESKTOP=false
    echo "  → No graphical desktop detected (headless mode)"
fi

echo "[4] Download Neovim v0.12.2"
if command -v nvim &> /dev/null && nvim --version | grep -q "v0.12.2"; then
    echo "  ✓ Neovim v0.12.2 already installed (skip)"
else
    echo "  → Installing Neovim v0.12.2..."
    curl -fsSLO https://github.com/neovim/neovim/releases/download/v0.12.2/nvim-linux-x86_64.tar.gz
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
    echo "  ✓ Neovim v0.12.2 installed"
fi

echo "[5] Configure update-alternatives for vi/vim"
sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/nvim 100
sudo update-alternatives --install /usr/bin/vim vim /usr/local/bin/nvim 100
sudo update-alternatives --set vi /usr/local/bin/nvim
sudo update-alternatives --set vim /usr/local/bin/nvim

if [ "$IS_DESKTOP" = true ]; then
    echo "[5a] Desktop packages (xclip, emoji fonts)"
    sudo apt install -y --no-install-recommends xclip fonts-noto-color-emoji

    echo "[5b] Meslo Nerd Font"
    if fc-list | grep -q "MesloLGS NF"; then
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

    echo "[5c] Ghostty terminal"
    if command -v ghostty &> /dev/null; then
        echo "  ✓ Ghostty already installed (skip)"
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
    echo "[5a] Skipping desktop packages (headless mode)"
    echo "[5b] Skipping Meslo Nerd Font (headless mode)"
    echo "[5c] Skipping Ghostty (headless mode)"
fi

echo "[7] Go v1.26.4"
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

export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin"

if ! command -v go >/dev/null 2>&1; then
    echo "ERROR: Go installation failed"
    exit 1
fi
echo "Go installed: $(go version)"

echo "[8] nvm + Node LTS"
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

echo "[9] .NET 10"
if command -v dotnet &> /dev/null && dotnet --list-sdks | grep -q "^10\."; then
    echo "  ✓ .NET 10 SDK already installed (skip)"
else
    echo "  → Installing .NET 10 SDK..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    sudo tee /etc/apt/sources.list.d/microsoft-prod.list >/dev/null <<'EOF'
deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main
EOF
    sudo apt update
    sudo apt install -y dotnet-sdk-10.0
    echo "  ✓ .NET 10 SDK installed"
fi

echo "[10] Python 3"
sudo apt install -y python3 python3-pip python3-venv

echo "[11] Rust for tools"
if ! command -v rustc >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs -o /tmp/rustup.sh
    sh /tmp/rustup.sh -y
fi
. "$HOME/.cargo/env"
cargo install stylua taplo-cli

echo "[12] Deploy neovim config via stow"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/nvim" ]; then
    if [ -L "$HOME/.config/nvim" ]; then
        stow -d "$SCRIPT_DIR" -t "$HOME" -R nvim
        echo "  ✓ neovim config restowed"
    else
        if [ -d "$HOME/.config/nvim" ]; then
            TIMESTAMP=$(date +%Y%m%d-%H%M%S)
            BACKUP_DIR="$HOME/.config/nvim-backup-$TIMESTAMP"
            echo "  → Backing up existing nvim config to $BACKUP_DIR"
            mv "$HOME/.config/nvim" "$BACKUP_DIR"
        fi
        stow -d "$SCRIPT_DIR" -t "$HOME" nvim
        echo "  ✓ neovim config stowed"
    fi
else
    echo "  → No nvim package in dotfiles (skip)"
fi

echo "[13] Verify essentials"
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
