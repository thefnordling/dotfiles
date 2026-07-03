#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.local/shell-backups/shell-$(date +%Y%m%d-%H%M%S)"

OS="$(uname -s)"

echo "=== Shell Setup Script ==="
echo "This script will:"
echo "  1. Uninstall oh-my-zsh (if present)"
echo "  2. Install zsh and GNU Stow"
echo "  3. Optionally change default shell to zsh"
echo "  4. Install powerlevel10k"
echo "  5. Apply dotfiles using GNU Stow"
echo "  6. Install Nerd Font (macOS only, for powerlevel10k / eza icons)"
echo "  7. Install tmux plugins (catppuccin, vim-tmux-navigator)"
echo "  8. Install tmux-mem-cpu-load"
echo "  9. Create secrets file for local environment"
echo ""

# ---------------------------------------------------------------------------
# OS helpers
# ---------------------------------------------------------------------------
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

apt_install() {
    local pkgs="$1"
    sudo apt-get update
    sudo apt-get install -y $pkgs
}

# ---------------------------------------------------------------------------
# Detect / auto-install Homebrew on macOS
# ---------------------------------------------------------------------------
ensure_brew() {
    if ! command -v brew &>/dev/null; then
        echo "  → Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon default path
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

echo "[1/8] Checking for oh-my-zsh..."
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

echo "[2/8] Installing zsh and GNU Stow..."
if is_macos; then
    ensure_brew

    # On macOS, brew zsh may not be in PATH yet; detect via brew --prefix
    if ! command -v zsh &>/dev/null || [ "$(which zsh 2>/dev/null)" = "/bin/zsh" ]; then
        brew_install zsh
    fi
    for pkg in stow tmux vivid eza fd; do
        brew_install "$pkg"
    done
else
    MISSING_PKGS=""
    for pkg in zsh stow tmux vivid eza fd; do
        if ! command -v "$pkg" &> /dev/null; then
            MISSING_PKGS="$MISSING_PKGS $pkg"
        fi
    done
    if [ -n "$MISSING_PKGS" ]; then
        apt_install "$MISSING_PKGS"
        echo "  ✓ Installation complete"
    else
        echo "  ✓ All packages already installed"
    fi
fi

echo "[3/8] Changing default shell to zsh..."
if is_macos; then
    CURRENT_SHELL=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
    ZSH_PATH="$(brew --prefix)/bin/zsh"
else
    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
    ZSH_PATH=$(which zsh)
fi

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    echo "  ✓ Default shell already zsh (skip)"
else
    echo "  Current shell: $CURRENT_SHELL"
    echo "  Target shell: $ZSH_PATH"
    read -p "  Change default shell to $ZSH_PATH? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  → Changing default shell to $ZSH_PATH..."
        if ! grep -q "^$ZSH_PATH$" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        chsh -s "$ZSH_PATH"
        echo "  ✓ Default shell changed to $ZSH_PATH (restart session to take effect)"
    else
        echo "  ✓ Keeping current shell"
    fi
fi

echo "[4/8] Installing powerlevel10k..."
P10K_DIR="$HOME/.local/share/powerlevel10k"
    if [ -d "$P10K_DIR" ]; then
        echo "  → powerlevel10k already exists, updating..."
        if [ -f "$P10K_DIR/.git" ]; then
            (cd "$P10K_DIR" && git fetch --unshallow 2>/dev/null || true && git pull) || echo "  → powerlevel10k update skipped"
        fi
        echo "  ✓ powerlevel10k checked"
    else
        echo "  → Cloning powerlevel10k..."
        mkdir -p "$HOME/.local/share"
        git clone https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
        echo "  ✓ powerlevel10k installed"
    fi

echo "[5/8] Applying dotfiles with GNU Stow..."

for pkg in zsh powerlevel10k tmux; do
    if [ ! -d "$SCRIPT_DIR/$pkg" ]; then
        echo "Error: stow package '$pkg' not found in $SCRIPT_DIR"
        exit 1
    fi
done

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

_stow_hide_steam_symlinks() {
    mkdir -p /tmp/stow-steam-backup
    [ -L "$HOME/.steampid" ] && mv "$HOME/.steampid" /tmp/stow-steam-backup/ 2>/dev/null || true
    [ -L "$HOME/.steampath" ] && mv "$HOME/.steampath" /tmp/stow-steam-backup/ 2>/dev/null || true
}

_stow_restore_steam_symlinks() {
    [ -L /tmp/stow-steam-backup/.steampid ] && mv /tmp/stow-steam-backup/.steampid "$HOME/" 2>/dev/null || true
    [ -L /tmp/stow-steam-backup/.steampath ] && mv /tmp/stow-steam-backup/.steampath "$HOME/" 2>/dev/null || true
    rmdir /tmp/stow-steam-backup 2>/dev/null || true
}

if [ -L "$HOME/.zshrc" ]; then
    echo "  → Restowing zsh package..."
    _stow_hide_steam_symlinks
    stow -d "$SCRIPT_DIR" -t "$HOME" -R zsh
    _stow_restore_steam_symlinks
else
    echo "  → Stowing zsh package..."
    stow -d "$SCRIPT_DIR" -t "$HOME" zsh
fi
echo "  ✓ zsh configs applied"

if [ -L "$HOME/.p10k.zsh" ]; then
    echo "  → Restowing powerlevel10k package..."
    _stow_hide_steam_symlinks
    stow -d "$SCRIPT_DIR" -t "$HOME" -R powerlevel10k
    _stow_restore_steam_symlinks
else
    echo "  → Stowing powerlevel10k package..."
    stow -d "$SCRIPT_DIR" -t "$HOME" powerlevel10k
fi
echo "  ✓ powerlevel10k config applied"

if [ -L "$HOME/.tmux.conf" ]; then
    echo "  → Restowing tmux package..."
    _stow_hide_steam_symlinks
    stow -d "$SCRIPT_DIR" -t "$HOME" -R tmux
    _stow_restore_steam_symlinks
else
    echo "  → Stowing tmux package..."
    stow -d "$SCRIPT_DIR" -t "$HOME" tmux
fi
echo "  ✓ tmux config applied"

echo "[6/8] Installing tmux plugins..."
mkdir -p "$HOME/.config/tmux/plugins"

if [ -d "$HOME/.config/tmux/plugins/catppuccin" ]; then
    echo "  → Updating existing catppuccin theme..."
    if [ -f "$HOME/.config/tmux/plugins/catppuccin/.git" ]; then
        (cd "$HOME/.config/tmux/plugins/catppuccin" && git fetch --unshallow 2>/dev/null || true && git pull) || echo "  → catppuccin update skipped"
    fi
    echo "  ✓ catppuccin theme checked"
else
    echo "  → Installing catppuccin theme..."
    git clone https://github.com/catppuccin/tmux.git "$HOME/.config/tmux/plugins/catppuccin"
    echo "  ✓ catppuccin theme installed"
fi

if [ -d "$HOME/.config/tmux/plugins/vim-tmux-navigator" ]; then
    echo "  → Updating existing vim-tmux-navigator..."
    if [ -f "$HOME/.config/tmux/plugins/vim-tmux-navigator/.git" ]; then
        (cd "$HOME/.config/tmux/plugins/vim-tmux-navigator" && git fetch --unshallow 2>/dev/null || true && git pull) || echo "  → vim-tmux-navigator update skipped"
    fi
    echo "  ✓ vim-tmux-navigator checked"
else
    echo "  → Installing vim-tmux-navigator..."
    git clone https://github.com/christoomey/vim-tmux-navigator.git "$HOME/.config/tmux/plugins/vim-tmux-navigator"
    echo "  ✓ vim-tmux-navigator installed"
fi

echo "[7/9] Installing Nerd Font for powerlevel10k and eza icons..."
if is_macos; then
    ensure_brew
    FONT_NAME="font-meslo-lg-nerd-font"
    if brew list --cask "$FONT_NAME" &>/dev/null 2>&1; then
        echo "  ✓ Meslo Nerd Font already installed"
    else
        echo "  → Installing Meslo Nerd Font..."
        echo y | CI=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --cask "$FONT_NAME"
        echo "  ✓ Meslo Nerd Font installed. Set your terminal font to 'MesloLGS NF Regular'."
    fi

    if ! brew list --cask supercmdlabs/supercmd/supercmd &>/dev/null 2>&1; then
        echo "  → Installing SuperCmd launcher..."
        echo y | CI=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --cask supercmdlabs/supercmd/supercmd
        echo "  ✓ SuperCmd installed"
    else
        echo "  ✓ SuperCmd already installed"
    fi
else
    echo "  → Nerd Font installation via script is not supported on Linux."
    echo "  → Install manually (e.g. 'sudo apt install fonts-firacode' or download Meslo from Nerd Fonts site)."
fi

echo "[8/9] Installing tmux-mem-cpu-load..."

if [ -x "$HOME/.local/bin/tmux-mem-cpu-load" ]; then
    echo "  ✓ tmux-mem-cpu-load already installed"
else
    echo "  → Installing build dependencies..."

    if is_macos; then
        # Xcode CLT provides clang (which aliases gcc/g++), make, etc.
        if ! xcode-select -p &>/dev/null; then
            echo "  → Xcode Command Line Tools not found. Run 'xcode-select --install' first, then re-run this script."
            echo "  → Skipping tmux-mem-cpu-load for now."
        else
            brew_install cmake
            _do_build=true
        fi
    else
        MISSING_BUILD_PKGS=""
        for pkg in cmake gcc g++ make; do
            if ! command -v "$pkg" &> /dev/null; then
                MISSING_BUILD_PKGS="$MISSING_BUILD_PKGS $pkg"
            fi
        done
        if [ -n "$MISSING_BUILD_PKGS" ]; then
            apt_install "$MISSING_BUILD_PKGS"
        fi
        _do_build=true
    fi

    if [ "${_do_build:-false}" = true ]; then
        echo "  → Cloning tmux-mem-cpu-load..."
        TMUX_MEM_DIR="/tmp/tmux-mem-cpu-load-build"
        rm -rf "$TMUX_MEM_DIR"
        git clone https://github.com/thewtex/tmux-mem-cpu-load.git "$TMUX_MEM_DIR"

        echo "  → Building tmux-mem-cpu-load..."
        (cd "$TMUX_MEM_DIR" && cmake -DCMAKE_INSTALL_PREFIX="$HOME/.local" . && make && make install) || {
            echo "  → Build failed, skipping"
        }

        rm -rf "$TMUX_MEM_DIR"
        if [ -x "$HOME/.local/bin/tmux-mem-cpu-load" ]; then
            echo "  ✓ tmux-mem-cpu-load installed"
        else
            echo "  → tmux-mem-cpu-load installation skipped"
        fi
    fi
fi

echo "[9/9] Setting up secrets file..."
SECRETS_DIR="$HOME/.config/secrets"
SECRETS_FILE="$SECRETS_DIR/environment"
if [ -f "$SECRETS_FILE" ]; then
    echo "  ✓ secrets file already exists (skip)"
else
    if [ -d "$SECRETS_DIR" ] && [ ! -x "$SECRETS_DIR" ]; then
        echo "  → WARNING: $SECRETS_DIR has restricted permissions, attempting to fix..."
        chmod 700 "$SECRETS_DIR" 2>/dev/null || sudo chmod 700 "$SECRETS_DIR" 2>/dev/null || {
            echo "  → ERROR: Cannot fix permissions on $SECRETS_DIR"
            echo "  → Please run: chmod 700 ~/.config/secrets"
            echo "  → Skipping secrets file creation"
        }
    fi
    if [ -x "$SECRETS_DIR" ]; then
        touch "$SECRETS_FILE"
        chmod 600 "$SECRETS_FILE"
        cat >> "$SECRETS_FILE" << 'EOF'
# Secrets and local environment variables
# This file is NOT tracked in dotfiles - add your private keys, API tokens, etc. here
#
# Example:
# export OPENAI_API_KEY="sk-..."
# export ANTHROPIC_API_KEY="sk-ant-..."

EOF
        echo "  → Created $SECRETS_FILE (add your secrets here)"
    fi
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
