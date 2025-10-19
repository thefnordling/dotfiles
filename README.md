# dotfiles

My Linux environment configuration, managed with GNU Stow.

## Installation

Clone this repository to your home directory:

```bash
git clone https://github.com/thefnordling/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
chmod +x *.sh
```

## Setup Instructions

Run these scripts in order for a complete development environment setup:

### 1. Shell Environment Setup (Required First)

```bash
./setup-shell.sh
```

This script will:

- Remove oh-my-zsh if present
- Install zsh, GNU Stow, and tmux
- Change your default shell to zsh
- Install powerlevel10k theme
- Apply shell configurations using GNU Stow

After running the script, install tmux plugins:

```bash
tmux
# Press Ctrl-a I (capital i) to install plugins
```

### 2. Development Tools Setup

```bash
./setup-nvim.sh
```

**Note**: This requires `setup-shell.sh` to be run first.

This script will:

- Install Neovim v0.11.3
- Install development tools (Go, Node via NVM, Python, .NET)
- Install Meslo Nerd Font
- Clone kickstart.nvim configuration

# 3. GitHub Credential Manager

```bash
./setup-ghcm.sh
```

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
