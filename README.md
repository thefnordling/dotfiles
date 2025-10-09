# dotfiles

My Linux environment configuration, managed with GNU Stow.

## Installation

Clone this repository to your home directory:

```bash
git clone https://github.com/thefnordling/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
chmod +x setup-shell.sh setup-nvim.sh
```

## Prerequisites

Install GNU Stow:

```bash
sudo apt-get install stow
```

## Setup Instructions

Run these scripts in order for a complete development environment setup:

### 1. Shell Environment Setup (Required First)

```bash
./setup-shell.sh
```

This script will:

- Remove oh-my-zsh if present
- Install zsh
- Change your default shell to zsh
- Install powerlevel10k theme
- Apply shell configurations using GNU Stow

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
./setup-ghcr.sh
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
