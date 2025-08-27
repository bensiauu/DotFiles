# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository containing personal configuration files for various development tools and applications. The repository uses a **manual symlink-based management system** where configuration files are organized in separate directories and manually linked to their expected locations in the home directory.

## Configuration Management

### Symlink Structure
The repository uses manual symlinks from the home directory to dotfiles:
- `~/.zshrc -> DotFiles/zsh/.zshrc`
- `~/.config/kitty -> ../DotFiles/kitty/.config/kitty`
- `~/.config/doom -> ../DotFiles/doom/.config/doom`
- `~/.config/zed -> ../DotFiles/zed/.config/zed`

### Directory Organization
Most configuration directories follow this pattern:
```
tool-name/
├── .config/
│   └── tool-name/
│       └── config-files
```

Some configs (zsh, tmux, wezterm) store files directly in the root directory.

## Key Configuration Categories

### Development Environment
- **zsh/**: Main shell configuration using zinit plugin manager with powerlevel10k
- **nvim/**: Neovim using LazyVim framework
- **doom/**: Doom Emacs configuration
- **emacs/**: Standard Emacs configuration
- **helix/**: Helix editor with Kanagawa theme

### Terminal Emulators
- **wezterm/**: WezTerm with Kanagawa theme, SF Mono font, tmux-like keybindings
- **kitty/**: Kitty terminal emulator
- **ghostty/**: Ghostty terminal configuration

### Window Management
- **hypr/**: Hyprland window manager configuration
- **waybar/**: Waybar status bar for Hyprland
- **tmux/**: Terminal multiplexer
- **zellij/**: Alternative terminal multiplexer

### Development Tools Setup (from zsh/.zshrc)
- **Python**: pyenv for version management (`$PYENV_ROOT`, pyenv init)
- **Node.js**: Both nvm and n version managers configured
- **Go**: Go binary paths configured
- **Editor**: Primary editor set as `nvim` via `$EDITOR`

## Common Development Commands

### Shell and Environment
- Zsh uses zinit plugin manager - will auto-install on first run if missing
- Powerlevel10k prompt configuration: `p10k configure`
- Plugin management: zinit commands for updating/managing plugins

### Editor Commands
- Primary editor: `nvim` (aliased as `v`)
- Emacs: Available via `$EMACS` environment variable (aliased as `e`)
- LazyVim: Standard LazyVim commands and shortcuts apply

### Git Aliases (from .zshrc)
- `gs` - git status
- `gl` - git log --oneline --graph --decorate

## Architecture Notes

### Theme Consistency
Several configurations use the **Kanagawa** theme:
- Helix: `theme = "kanagawa"`
- WezTerm: `color_scheme = "Kanagawa (Gogh)"`

### Plugin Management
- **Zsh**: Uses zinit for plugin management with auto-installation
- **Neovim**: Uses LazyVim framework
- **Emacs**: Uses package.el with custom configuration

### Path Management
The zsh configuration sets up comprehensive PATH management for:
- Local binaries (`~/.local/bin`)
- Node.js tools (`~/.npm-global/bin`, `~/.n/bin`)
- Go binaries (`~/go/bin`, `/usr/local/go/bin`)
- Python tools (pyenv integration)

## Installation Notes

This repository lacks automated setup scripts. Installation requires:
1. Clone repository to `~/DotFiles`
2. Manually create symlinks from home directory to appropriate config files
3. Install required dependencies (pyenv, nvm, zinit, etc.) separately
4. Run initial setup commands (p10k configure, etc.)

## File Modifications

When modifying configurations:
- Changes to symlinked files automatically apply to active configs
- Zsh changes require `source ~/.zshrc` or new terminal
- Editor configs typically reload automatically or on restart
- Window manager configs may require restart or reload commands