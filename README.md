# dotfiles

My Linux environment configuration, managed with GNU Stow.

## Installation

Clone this repository to your home directory:

```bash
git clone https://github.com/thefnordling/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
chmod +x *.sh
```

## Stowed Packages

| Package | What it manages |
|---------|----------------|
| `zsh` | `.zshrc`, `.zshenv`, `.zprofile` |
| `powerlevel10k` | `.p10k.zsh` + prompt geometry config |
| `tmux` | `.tmux.conf` |
| `nvim` | `.config/nvim/` (custom lua config) |
| `ghostty` | `.config/ghostty/` |
| `opencode` | `.config/opencode/` |

## Setup Instructions

Run these scripts in order for a complete development environment setup:

### 1. Shell Environment Setup (Required First)

```bash
./setup-shell.sh
```

This script will:

- Remove oh-my-zsh if present
- Install zsh, GNU Stow, tmux, vivid, and eza
- Change your default shell to zsh
- Install powerlevel10k theme
- Install catppuccin tmux theme + vim-tmux-navigator
- Install tmux-mem-cpu-load
- Apply shell configurations using GNU Stow
- Create a secrets file at `~/.config/secrets/environment`

### 2. Development Tools Setup

```bash
./setup-nvim.sh
```

**Note**: This requires `setup-shell.sh` to be run first.

This script will:

- Install Neovim v0.12.2
- Install Go v1.26.4
- Install Node.js via NVM (LTS)
- Install Python 3
- Install .NET 10 SDK
- Install Rust + stylua + taplo-cli
- Install Meslo Nerd Font (desktop only)
- Install Ghostty terminal (desktop only)
- Install neovim config via GNU Stow
- Configure update-alternatives for vi/vim to point to nvim

### 3. GitHub Credential Manager

```bash
./setup-ghcm.sh
```

Sets up GPG + pass + Git Credential Manager for secure GitHub authentication.

## Manual Configuration Updates

After editing dotfiles in this repository, apply changes with:

```bash
cd ~/code/dotfiles

# Restow shell configs
stow -t ~ -R zsh

# Restow powerlevel10k theme
stow -t ~ -R powerlevel10k

# Or restow everything
stow -t ~ -R */
```
