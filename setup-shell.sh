#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/tmp/shell-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Shell Setup Script ==="
echo "This script will:"
echo "  1. Uninstall oh-my-zsh (if present)"
echo "  2. Install zsh and GNU Stow"
echo "  3. Optionally change default shell to zsh"
echo "  4. Install powerlevel10k"
echo "  5. Apply dotfiles using GNU Stow"
echo "  6. Install tmux plugins (catppuccin, vim-tmux-navigator)"
echo "  7. Install tmux-mem-cpu-load"
echo ""

echo "[1/5] Checking for oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  → oh-my-zsh detected, uninstalling..."
    
    if [ -f "$HOME/.zshrc" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
        echo "  → Backed up existing .zshrc to $BACKUP_DIR"
    fi
    
    rm -rf "$HOME/.oh-my-zsh"
    echo "  ✓ oh-my-zsh removed"
else
    echo "  ✓ oh-my-zsh not installed (skip)"
fi

echo "[2/5] Installing zsh and GNU Stow..."
NEED_INSTALL=0
if ! command -v zsh &> /dev/null; then
    echo "  → zsh not found, will install"
    NEED_INSTALL=1
else
    echo "  ✓ zsh already installed"
fi

if ! command -v stow &> /dev/null; then
    echo "  → stow not found, will install"
    NEED_INSTALL=1
else
    echo "  ✓ stow already installed"
fi

if ! command -v tmux &> /dev/null; then
    echo "  → tmux not found, will install"
    NEED_INSTALL=1
else
    echo "  ✓ tmux already installed"
fi

if ! command -v vivid &> /dev/null; then
    echo "  → vivid not found, will install"
    NEED_INSTALL=1
else
    echo "  ✓ vivid already installed"
fi

if [ $NEED_INSTALL -eq 1 ]; then
    sudo apt-get update
    sudo apt-get install -y zsh stow tmux vivid
    echo "  ✓ Installation complete"
fi

echo "[3/5] Changing default shell to zsh..."
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    echo "  ✓ Default shell already zsh (skip)"
else
    echo "  Current shell: $CURRENT_SHELL"
    echo "  Target shell: $ZSH_PATH"
    read -p "  Change default shell to zsh? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  → Changing default shell to zsh..."
        if ! grep -q "^$ZSH_PATH$" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        chsh -s "$ZSH_PATH"
        echo "  ✓ Default shell changed to zsh (restart session to take effect)"
    else
        echo "  ✓ Keeping current shell"
    fi
fi

echo "[4/5] Installing powerlevel10k..."
P10K_DIR="$HOME/.local/share/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
    echo "  → powerlevel10k already exists, updating..."
    cd "$P10K_DIR"
    git pull
    echo "  ✓ powerlevel10k updated"
else
    echo "  → Cloning powerlevel10k..."
    mkdir -p "$HOME/.local/share"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    echo "  ✓ powerlevel10k installed"
fi

echo "[5/5] Applying dotfiles with GNU Stow..."

for config in .zshrc .zshenv .zprofile; do
    if [ -f "$HOME/$config" ] && [ ! -L "$HOME/$config" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/$config" "$BACKUP_DIR/"
        echo "  → Backed up existing $config to $BACKUP_DIR"
    fi
done

if [ -f "$HOME/.p10k.zsh" ] && [ ! -L "$HOME/.p10k.zsh" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.p10k.zsh" "$BACKUP_DIR/"
    echo "  → Backed up existing .p10k.zsh to $BACKUP_DIR"
fi

if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.tmux.conf" "$BACKUP_DIR/"
    echo "  → Backed up existing .tmux.conf to $BACKUP_DIR"
fi

cd "$SCRIPT_DIR"

if [ -L "$HOME/.zshrc" ]; then
    echo "  → Restowing zsh package..."
    stow -t ~ -R zsh
else
    echo "  → Stowing zsh package..."
    stow -t ~ zsh
fi
echo "  ✓ zsh configs applied"

if [ -L "$HOME/.p10k.zsh" ]; then
    echo "  → Restowing powerlevel10k package..."
    stow -t ~ -R powerlevel10k
else
    echo "  → Stowing powerlevel10k package..."
    stow -t ~ powerlevel10k
fi
echo "  ✓ powerlevel10k config applied"

if [ -L "$HOME/.tmux.conf" ]; then
    echo "  → Restowing tmux package..."
    stow -t ~ -R tmux
else
    echo "  → Stowing tmux package..."
    stow -t ~ tmux
fi
echo "  ✓ tmux config applied"

echo "[6/6] Installing tmux plugins..."
mkdir -p "$HOME/.config/tmux/plugins"

if [ -d "$HOME/.config/tmux/plugins/catppuccin" ]; then
    echo "  → Updating existing catppuccin theme..."
    cd "$HOME/.config/tmux/plugins/catppuccin"
    git pull
    cd "$SCRIPT_DIR"
    echo "  ✓ catppuccin theme updated"
else
    echo "  → Installing catppuccin theme..."
    git clone https://github.com/catppuccin/tmux.git "$HOME/.config/tmux/plugins/catppuccin"
    echo "  ✓ catppuccin theme installed"
fi

if [ -d "$HOME/.config/tmux/plugins/vim-tmux-navigator" ]; then
    echo "  → Updating existing vim-tmux-navigator..."
    cd "$HOME/.config/tmux/plugins/vim-tmux-navigator"
    git pull
    cd "$SCRIPT_DIR"
    echo "  ✓ vim-tmux-navigator updated"
else
    echo "  → Installing vim-tmux-navigator..."
    git clone https://github.com/christoomey/vim-tmux-navigator.git "$HOME/.config/tmux/plugins/vim-tmux-navigator"
    echo "  ✓ vim-tmux-navigator installed"
fi

echo "[7/7] Installing tmux-mem-cpu-load..."
if command -v tmux-mem-cpu-load &> /dev/null; then
    echo "  ✓ tmux-mem-cpu-load already installed"
else
    echo "  → Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y cmake build-essential
    
    echo "  → Cloning tmux-mem-cpu-load..."
    TMUX_MEM_DIR="/tmp/tmux-mem-cpu-load-build"
    rm -rf "$TMUX_MEM_DIR"
    git clone https://github.com/thewtex/tmux-mem-cpu-load.git "$TMUX_MEM_DIR"
    
    echo "  → Building tmux-mem-cpu-load..."
    cd "$TMUX_MEM_DIR"
    cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local .
    make
    make install
    
    cd "$SCRIPT_DIR"
    rm -rf "$TMUX_MEM_DIR"
    echo "  ✓ tmux-mem-cpu-load installed"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. Your shell environment is now configured!"
if [ -d "$BACKUP_DIR" ]; then
    echo ""
    echo "Backups saved to: $BACKUP_DIR"
fi
