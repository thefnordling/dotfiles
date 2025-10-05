# dotfiles

My Linux environment configuration, managed with GNU Stow.

## Installation

Clone this repository to your home directory:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/code/dotfiles
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

### 3. Restart Your Terminal

```bash
exec zsh
```

## Idempotency

Both scripts are fully idempotent and safe to re-run:
- They detect what's already installed and skip those steps
- Safe to run across multiple hosts
- Updates tools when re-run (e.g., powerlevel10k gets updated)

## Manual Configuration Updates

After editing dotfiles in this repository, apply changes with:

```bash
cd ~/code/dotfiles

# Restow shell configs
stow -R zsh

# Restow powerlevel10k theme
stow -R powerlevel10k

# Or restow everything
stow -R */
```

## Package Structure

- `zsh/` - Shell configuration (.zshenv, .zprofile, .zshrc)
- `powerlevel10k/` - Powerlevel10k theme configuration (.p10k.zsh)
- `ghostty/` - Ghostty terminal configuration
- `opencode/` - OpenCode editor configuration
- `wrenai/` - WrenAI configuration

## Troubleshooting

**Neovim plugins not installing?**
- Ensure you ran `setup-shell.sh` first
- Restart your terminal: `exec zsh`
- Check that NVM is loaded: `nvm --version`
- Check that Go is in PATH: `go version`

**Stow conflicts?**
- Existing config files will be backed up to `~/.shell-backup-*`
- If you get stow conflicts, manually remove or backup the conflicting files

