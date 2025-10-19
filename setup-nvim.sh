#!/usr/bin/env bash
set -euo pipefail

if [ ! -L "$HOME/.zshrc" ]; then
    echo "ERROR: Shell configuration not found."
    echo "Please run ./setup-shell.sh first to set up your shell environment."
    exit 1
fi

echo "[1] Download Neovim v0.11.3"
if command -v nvim &> /dev/null && nvim --version | grep -q "v0.11.3"; then
    echo "  ✓ Neovim v0.11.3 already installed (skip)"
else
    echo "  → Installing Neovim v0.11.3..."
    curl -fsSLO https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.tar.gz
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
    echo "  ✓ Neovim v0.11.3 installed"
fi

echo "[2] Dev packages (without neovim/nodejs from apt)"
sudo apt install -y --no-install-recommends git build-essential unzip curl xclip ripgrep fd-find fontconfig fonts-noto-color-emoji make gcc zsh netcat

echo "[3] Remove conflicting packages"
sudo apt remove -y vim vim-tiny vi neovim nodejs libnode-dev libnode109 || true
sudo apt autoremove -y || true

echo "[4] Symlinks for nvim and fd"
sudo ln -sf /usr/local/bin/nvim /usr/bin/vi
sudo ln -sf /usr/local/bin/nvim /usr/bin/vim
sudo ln -sf /usr/local/bin/nvim /usr/local/bin/vi
sudo ln -sf /usr/local/bin/nvim /usr/local/bin/vim
command -v fd >/dev/null || sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd

echo "[5] Configure update-alternatives for vi/vim"
sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/nvim 100
sudo update-alternatives --install /usr/bin/vim vim /usr/local/bin/nvim 100
sudo update-alternatives --set vi /usr/local/bin/nvim
sudo update-alternatives --set vim /usr/local/bin/nvim

echo "[5] Meslo font"
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

echo "[6] Go v1.25.0"
GO_VERSION=1.25.0

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

export PATH="$PATH:/usr/local/go/bin"

if ! command -v go >/dev/null 2>&1; then
    echo "ERROR: Go installation failed"
    exit 1
fi
echo "Go installed: $(go version)"

echo "[7] nvm + Node LTS"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
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

echo "[8] .NET 8"
if command -v dotnet &> /dev/null && dotnet --list-sdks | grep -q "^8\."; then
    echo "  ✓ .NET 8 SDK already installed (skip)"
else
    echo "  → Installing .NET 8 SDK..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    sudo tee /etc/apt/sources.list.d/microsoft-prod.list >/dev/null <<'EOF'
deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main
EOF
    sudo apt update
    sudo apt install -y dotnet-sdk-8.0
    echo "  ✓ .NET 8 SDK installed"
fi

echo "[9] Python 3"
sudo apt install -y python3 python3-pip python3-venv

echo "[10] Verify tools"
echo "Verifying installations:"
for b in nvim vi vim rg fd git go node npm dotnet python3; do
    if command -v "$b" >/dev/null 2>&1; then
        case "$b" in
        nvim | go | node | npm | dotnet | python3)
            version=$($b --version 2>&1 | head -1 || true)
            ;;
        *)
            version="OK"
            ;;
        esac
        printf '  %-10s: %s (%s)\n' "$b" "$(command -v "$b")" "$version"
    else
        printf '  %-10s: MISSING\n' "$b"
    fi
done

echo "[11] Clone config"
if [ -d "$HOME/.config/nvim" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR="$HOME/.config/nvim-backup-$TIMESTAMP"
    echo "  → Backing up existing nvim config to $BACKUP_DIR"
    mv "$HOME/.config/nvim" "$BACKUP_DIR"
fi
git clone https://github.com/thefnordling/kickstart.nvim.git "$HOME/.config/nvim"

echo "Done! Installation complete."
echo ""
echo "Next steps:"
echo "  1. Set terminal font to 'MesloLGS NF'"
echo "  2. Restart your shell or run: source ~/.bashrc  (or ~/.zshrc)"
echo "  3. Run: nvim"
echo ""
