#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/tmp/shell-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Shell Setup Script ==="
echo "This script will:"
echo "  1. Uninstall oh-my-zsh (if present)"
echo "  2. Install zsh"
echo "  3. Change default shell to zsh"
echo "  4. Install powerlevel10k"
echo "  5. Apply dotfiles using GNU Stow"
echo ""

if ! command -v stow &> /dev/null; then
    echo "ERROR: GNU Stow is not installed. Please install it first:"
    echo "  sudo apt-get install stow"
    exit 1
fi

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

echo "[2/5] Installing zsh..."
if command -v zsh &> /dev/null; then
    echo "  ✓ zsh already installed (skip)"
else
    echo "  → Installing zsh via apt..."
    sudo apt-get update
    sudo apt-get install -y zsh
    echo "  ✓ zsh installed"
fi

echo "[3/5] Changing default shell to zsh..."
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    echo "  ✓ Default shell already zsh (skip)"
else
    echo "  → Changing default shell to zsh..."
    if ! grep -q "^$ZSH_PATH$" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    chsh -s "$ZSH_PATH"
    echo "  ✓ Default shell changed to zsh (restart session to take effect)"
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
