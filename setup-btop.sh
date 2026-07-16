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

echo "[1] Install btop"
if is_macos; then
    brew_install btop
else
    if command -v btop &>/dev/null; then
        echo "  ✓ btop already installed ($(btop --version | head -1))"
    else
        echo "  → Installing btop..."
        sudo apt install -y btop
        echo "  ✓ btop installed"
    fi
fi

echo "[2] Download Catppuccin themes"

# Use a deterministic latest tag to avoid surprises on re-runs
CATPPUCCIN_BTOP_VER="1.0.0"
CATPPUCCIN_URL="https://github.com/catppuccin/btop/releases/download/${CATPPUCCIN_BTOP_VER}/themes.tar.gz"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$SCRIPT_DIR/btop/themes"
mkdir -p "$THEMES_DIR"

# Download the theme tarball into a temp file; skip if already present
THEME_TARBALL="$(mktemp /tmp/btop-theme-XXXXXX.tar.gz)"
curl -fsSL "$CATPPUCCIN_URL" -o "$THEME_TARBALL"

# Extract only the theme files we need into the dotfiles structure
for theme_file in catppuccin_mocha catppuccin_macchiato catppuccin_latte catppuccin_frappe; do
    local_path="$THEMES_DIR/${theme_file}.theme"
    if [ -f "$local_path" ]; then
        echo "  ✓ ${theme_file}.theme already in dotfiles (skip)"
    else
        mkdir -p /tmp/btop-extract
        tar -xzf "$THEME_TARBALL" -C /tmp/btop-extract "themes/${theme_file}.theme"
        cp "/tmp/btop-extract/themes/${theme_file}.theme" "$local_path"
        echo "  → ${theme_file}.theme added to dotfiles"
    fi
done

rm -rf /tmp/btop-extract
rm -f "$THEME_TARBALL"

echo "[3] Deploy btop config via stow"

# Initialize themes in dotfiles
mkdir -p "$SCRIPT_DIR/btop/themes"

# Write default config to dotfiles
echo "color_scheme = catppuccin_mocha" > "$SCRIPT_DIR/btop/btop.conf"

# Do nothing if no btop package exists
if [ ! -d "$SCRIPT_DIR/btop" ]; then
    echo "  → No btop package in dotfiles (skip)"
    exit 0
fi

function _stow_btop() {
    local target=".config/btop"
    if [ -L "$HOME/$target" ]; then
        stow -d "$SCRIPT_DIR" -t "$HOME" -R btop
        echo "  ✓ btop config restowed"
        return
    fi
    if [ -e "$HOME/$target" ]; then
        local ts
        ts=$(date +%Y%m%d-%H%M%S)
        local backup="$HOME/$target-backup-$ts"
        echo "  → Backing up existing $target to $backup"
        mv "$HOME/$target" "$backup"
    fi
    stow -d "$SCRIPT_DIR" -t "$HOME" btop
    echo "  ✓ btop config stowed to ~/.config/btop"
}

_stow_btop

echo "[4] btop is ready."
echo ""
echo "Tip: open btop and press 'l' → select 'Options' → choose a Catppuccin theme."
