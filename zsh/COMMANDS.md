# Zsh Configuration - Quick Reference

## 🚀 New Commands Available

### Interactive Git (Forgit)

| Command | Description |
|---------|-------------|
| `ga` | Interactive git add |
| `glo` | Interactive git log |
| `gd` | Interactive git diff |
| `gcf` | Interactive git checkout file |
| `gss` | Interactive git stash show |
| `grh` | Interactive git reset HEAD |

### Smart Directory Navigation

| Command | Description |
|---------|-------------|
| `z <pattern>` | Jump to directory (replaces cd) |
| `zi` | Interactive directory selection |
| `~config` | Jump to ~/.config |
| `~dots` | Jump to ~/DotFiles |

### Enhanced File Operations

| Command | Description |
|---------|-------------|
| `ls` | eza with icons (or enhanced ls) |
| `ll` | Long format with git status |
| `la` | All files with git status |
| `lt` | Tree view |
| `cat` | bat with syntax highlighting |

### Utility Functions

| Command | Description |
|---------|-------------|
| `mkcd <dir>` | Create directory and cd into it |
| `extract <file>` | Extract any archive format |
| `ff <pattern>` | Find files by name pattern |
| `zsh_bootstrap` | Check for missing tools |

## ⌨️ Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl+Space` | Accept autosuggestion |
| `Ctrl+R` | Search command history |
| `Ctrl+Right` | Jump forward by word |
| `Ctrl+Left` | Jump backward by word |
| `Ctrl+Backspace` | Delete word backward |
| `Ctrl+Delete` | Delete word forward |
| `↑` | History substring search up |
| `↓` | History substring search down |

## 🔍 fzf-tab Features

When using tab completion, you can:

- Use `,` and `.` to switch between completion groups
- See directory previews when completing `cd`
- See git diffs when completing git commands
- Use `Ctrl+C` to cancel completion

## 🛠 Maintenance Commands

| Command | Description |
|---------|-------------|
| `zinit update` | Update all plugins |
| `zinit status` | Check plugin status |
| `p10k configure` | Configure prompt theme |
| `source ~/.zshrc` | Reload configuration |
| `zsh_bootstrap` | Check for missing tools |

## 📂 Directory Shortcuts

| Shortcut | Path |
|----------|------|
| `cd ~config` | `cd ~/.config` |
| `cd ~dots` | `cd ~/DotFiles` |

## 🌍 Platform-Specific Notes

### All Platforms
- Configuration auto-detects your OS and adjusts accordingly
- Tools fallback gracefully if not installed

### Ubuntu/Debian Specific
- `bat` command available as `batcat`
- `fd` command available as `fdfind`
- Aliases handle these differences automatically

### macOS Specific
- Homebrew paths configured automatically
- Supports both Intel and Apple Silicon Macs

### WSL Specific
- Detects WSL environment automatically
- Uses Linux package managers appropriately

## 🆘 Quick Fixes

### Slow startup?
- NVM lazy loading should help
- Check for problematic plugins with `zinit times`

### Missing tools?
```bash
zsh_bootstrap  # Check what's missing
cd ~/DotFiles/zsh && ./install.sh  # Install everything
```

### Completion not working?
```bash
rm ~/.zcompdump*  # Clear completion cache
source ~/.zshrc   # Reload configuration
```

### Git integration issues?
```bash
zinit update wfxr/forgit  # Update forgit plugin
```