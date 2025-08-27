#!/bin/bash
# Zsh Configuration Install Script
# Supports macOS, Linux (Ubuntu/Debian, RHEL/Fedora), and WSL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Platform detection
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "arm64" ]]; then
            BREW_PREFIX="/opt/homebrew"
        else
            BREW_PREFIX="/usr/local"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
            PLATFORM="wsl"
        else
            PLATFORM="linux"
        fi
        BREW_PREFIX="/home/linuxbrew/.linuxbrew"
        
        # Detect Linux distribution
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            DISTRO=$ID
            DISTRO_VERSION=$VERSION_ID
        elif [[ -f /etc/redhat-release ]]; then
            DISTRO="rhel"
        elif [[ -f /etc/debian_version ]]; then
            DISTRO="debian"
        fi
    else
        PLATFORM="unknown"
    fi
    
    log_info "Detected platform: $PLATFORM"
    [[ "$DISTRO" ]] && log_info "Linux distribution: $DISTRO"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew
install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew already installed"
        return
    fi
    
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for this session
    if [[ "$PLATFORM" == "macos" ]]; then
        eval "$($BREW_PREFIX/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
}

# Install tools via package manager
install_tools_brew() {
    log_info "Installing tools via Homebrew..."
    local tools=("fzf" "bat" "ripgrep" "fd" "eza" "zoxide" "git-delta")
    
    for tool in "${tools[@]}"; do
        if ! brew list "$tool" &>/dev/null; then
            log_info "Installing $tool..."
            brew install "$tool"
        else
            log_info "$tool already installed"
        fi
    done
}

install_tools_apt() {
    log_info "Installing tools via apt..."
    sudo apt update
    
    # Map of tools and their apt package names
    declare -A apt_packages=(
        ["fzf"]="fzf"
        ["bat"]="batcat"  # Note: different name on Ubuntu
        ["ripgrep"]="ripgrep"
        ["fd"]="fd-find"  # Note: different name on Ubuntu
        ["zoxide"]="zoxide"
        ["git-delta"]="git-delta"
    )
    
    for tool in "${!apt_packages[@]}"; do
        local package="${apt_packages[$tool]}"
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "Installing $package..."
            sudo apt install -y "$package"
        else
            log_info "$package already installed"
        fi
    done
    
    # Install eza via cargo if available, or use alternative method
    if ! command_exists eza; then
        if command_exists cargo; then
            log_info "Installing eza via cargo..."
            cargo install eza
        else
            log_warning "eza not available, will use ls with aliases"
        fi
    fi
}

install_tools_dnf() {
    log_info "Installing tools via dnf..."
    
    local tools=("fzf" "bat" "ripgrep" "fd-find" "zoxide")
    
    for tool in "${tools[@]}"; do
        if ! rpm -q "$tool" &>/dev/null; then
            log_info "Installing $tool..."
            sudo dnf install -y "$tool"
        else
            log_info "$tool already installed"
        fi
    done
    
    # Install eza via cargo if available
    if ! command_exists eza; then
        if command_exists cargo; then
            log_info "Installing eza via cargo..."
            cargo install eza
        else
            log_warning "eza not available, will use ls with aliases"
        fi
    fi
}

# Install zinit
install_zinit() {
    local zinit_dir="$HOME/.zinit"
    if [[ -d "$zinit_dir" ]]; then
        log_info "zinit already installed"
        return
    fi
    
    log_info "Installing zinit..."
    mkdir -p "$zinit_dir"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_dir/bin"
    log_success "zinit installed successfully"
}

# Setup zsh as default shell
setup_zsh_shell() {
    if [[ "$SHELL" == *"zsh" ]]; then
        log_info "zsh is already the default shell"
        return
    fi
    
    local zsh_path
    zsh_path=$(command -v zsh)
    
    if [[ -z "$zsh_path" ]]; then
        log_error "zsh not found. Please install zsh first."
        return 1
    fi
    
    # Add zsh to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells; then
        log_info "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    
    log_info "Setting zsh as default shell..."
    chsh -s "$zsh_path"
    log_success "zsh set as default shell (restart terminal to take effect)"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p "$HOME/.zsh/cache"
    mkdir -p "$HOME/.config"
}

# Main installation function
main() {
    log_info "Starting zsh configuration installation..."
    
    detect_platform
    create_directories
    
    # Install tools based on platform
    case "$PLATFORM" in
        "macos")
            install_homebrew
            install_tools_brew
            ;;
        "linux"|"wsl")
            case "$DISTRO" in
                "ubuntu"|"debian")
                    install_tools_apt
                    ;;
                "fedora"|"rhel"|"centos")
                    install_tools_dnf
                    ;;
                *)
                    log_warning "Unknown Linux distribution. Trying to install Homebrew as fallback..."
                    install_homebrew
                    install_tools_brew
                    ;;
            esac
            ;;
        *)
            log_error "Unsupported platform: $PLATFORM"
            exit 1
            ;;
    esac
    
    install_zinit
    setup_zsh_shell
    
    log_success "Installation completed!"
    log_info "Please run 'source ~/.zshrc' or restart your terminal to activate the new configuration."
    
    # Show post-install instructions
    echo
    log_info "Post-installation steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Run 'p10k configure' to set up your prompt theme"
    echo "3. The configuration will automatically download and install zsh plugins on first use"
}

# Run main function
main "$@"