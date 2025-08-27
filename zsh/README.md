# Modern Zsh Configuration

A powerful, cross-platform zsh configuration optimized for development workflows with intelligent completions, modern CLI tools integration, and performance optimizations.

## 🌟 Features

- **Cross-platform compatibility**: Works on macOS, Linux (Ubuntu/Debian, RHEL/Fedora), and WSL
- **Intelligent completions**: Enhanced with fzf-tab for interactive fuzzy completion
- **Modern CLI tools integration**: eza, bat, ripgrep, zoxide, and more
- **Performance optimized**: Lazy loading for NVM, smart caching, and compiled configuration
- **Powerful plugins**: Syntax highlighting, autosuggestions, git integration
- **Automatic tool installation**: One-command setup script for all platforms

## 🚀 Quick Start

### Automatic Installation

The easiest way to set up the configuration:

```bash
# Clone or ensure you have the dotfiles repository
cd ~/DotFiles/zsh

# Run the installation script
./install.sh
```

The script will:
- Detect your platform (macOS, Linux distro, WSL)
- Install required CLI tools using the appropriate package manager
- Set up zinit plugin manager
- Configure zsh as your default shell

### Manual Setup

If you prefer manual installation or the automatic script doesn't work:

1. **Install zsh** (if not already installed)
2. **Install modern CLI tools** (see [Tools](#-tools) section)
3. **Symlink the configuration**:
   ```bash
   ln -sf ~/DotFiles/zsh/.zshrc ~/.zshrc
   ```
4. **Restart your terminal** or run `source ~/.zshrc`

## 🛠 Tools

### Essential Tools

These tools are required for full functionality:

| Tool | Purpose | Installation |
|------|---------|-------------|
| **fzf** | Fuzzy finder for completions and history | `brew install fzf` / `apt install fzf` / `dnf install fzf` |
| **ripgrep** | Modern grep replacement | `brew install ripgrep` / `apt install ripgrep` / `dnf install ripgrep` |
| **git** | Version control | Usually pre-installed |

### Modern CLI Tools

These tools provide enhanced functionality:

| Tool | Purpose | Package Names |
|------|---------|---------------|
| **eza** | Modern ls replacement | `brew install eza` / `cargo install eza` |
| **bat** | Cat with syntax highlighting | `brew install bat` / `apt install batcat` / `dnf install bat` |
| **zoxide** | Smart directory jumping | `brew install zoxide` / `apt install zoxide` / `dnf install zoxide` |
| **fd** | Modern find replacement | `brew install fd` / `apt install fd-find` / `dnf install fd-find` |
| **delta** | Better git diff viewer | `brew install git-delta` / `apt install git-delta` |

### Platform-Specific Package Names

Some tools have different package names on different platforms:

- **Ubuntu/Debian**: `batcat` (not `bat`), `fd-find` (not `fd`)
- **Fedora/RHEL**: Standard names
- **macOS**: Standard names via Homebrew

## 📱 Platform Support

### macOS

- Uses Homebrew as the primary package manager
- Automatically detects Apple Silicon vs Intel Macs
- Supports both `/opt/homebrew` (Apple Silicon) and `/usr/local` (Intel) paths

### Linux (Ubuntu/Debian)

- Uses apt package manager
- Handles package name differences (batcat, fd-find)
- Installs eza via cargo if available

### Linux (RHEL/Fedora/CentOS)

- Uses dnf/yum package manager
- Most tools available in standard repositories
- Falls back to cargo for eza if needed

### Windows Subsystem for Linux (WSL)

- Automatically detects WSL environment
- Uses Linux package managers (apt/dnf depending on distro)
- Supports Homebrew on Linux as fallback

## 🔧 Configuration Features

### Smart Completions

- **Case-insensitive matching**: Type `cd DOC` to match `Documents/`
- **Partial word matching**: Type `cd f-e` to match `foo-bar-example/`
- **Interactive completion**: Use fzf for visual selection
- **Git command previews**: See diffs and logs during tab completion
- **Directory previews**: See directory contents during completion

### Key Bindings

| Key Combination | Action |
|----------------|--------|
| `Ctrl+Space` | Accept autosuggestion |
| `Ctrl+R` | Search command history |
| `Ctrl+Right/Left` | Jump by word |
| `Ctrl+Backspace/Delete` | Delete word |
| `↑/↓` | History substring search |

### Modern Aliases

When modern tools are available:

```bash
ls    # eza with icons and colors
ll    # eza long format with git status
la    # eza all files with git status
lt    # eza tree view
cat   # bat with syntax highlighting
grep  # ripgrep with colors
cd    # zoxide smart jumping
```

### Plugin Features

- **Syntax highlighting**: Real-time command syntax highlighting
- **Autosuggestions**: Fish-like command suggestions from history
- **Git integration**: Interactive git commands with `forgit`
- **Auto-pairing**: Automatic bracket and quote pairing
- **History search**: Multi-word history search with highlighting

## 🚨 Troubleshooting

### "Command not found" Errors

Run the bootstrap function to check for missing tools:

```bash
zsh_bootstrap
```

### Slow Shell Startup

The configuration includes several optimizations:

- NVM lazy loading (loads only when needed)
- Smart completion caching
- Compiled configuration files
- Background tool checking

### Plugin Issues

Plugins are managed by zinit and auto-install on first use. If you encounter issues:

```bash
# Update all plugins
zinit update

# Reload configuration
source ~/.zshrc

# Check zinit status
zinit status
```

### Platform Detection Issues

Check your platform detection:

```bash
echo "Platform: $ZSH_PLATFORM"
echo "Distro: $ZSH_DISTRO"
```

## 🔄 Updating

### Update Plugins

```bash
zinit update
```

### Update Configuration

```bash
cd ~/DotFiles
git pull
source ~/.zshrc
```

### Re-run Installation

```bash
cd ~/DotFiles/zsh
./install.sh
```

## 📁 File Structure

```
zsh/
├── .zshrc          # Main configuration file
├── install.sh      # Cross-platform installation script
└── README.md       # This documentation
```

## 🎨 Customization

### Local Configuration

For machine-specific configurations that shouldn't be in version control:

```bash
# Create local config file
touch ~/.zshrc.local

# Add to end of .zshrc
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

### Powerlevel10k Theme

Configure your prompt:

```bash
p10k configure
```

### Adding Custom Plugins

Add to the plugin section in `.zshrc`:

```bash
zinit light "username/plugin-name"
```

## 🤝 Contributing

This configuration is part of a personal dotfiles repository. Feel free to:

1. Fork the repository
2. Make your changes
3. Test on multiple platforms
4. Submit a pull request

## 📄 License

This configuration is provided as-is for personal use. Feel free to adapt it to your needs.

---

*Happy shell-ing!* 🐚✨