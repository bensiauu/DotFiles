# use termgui color
export TERM=xterm-256color

### -----------------------------
### Platform Detection and Setup
### -----------------------------
# Detect platform for cross-platform compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
    export ZSH_PLATFORM="macos"
    # Configure Homebrew path for macOS
    if [[ -d "/opt/homebrew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/homebrew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
        export ZSH_PLATFORM="wsl"
    else
        export ZSH_PLATFORM="linux"
    fi
    # Configure Homebrew path for Linux/WSL
    if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    
    # Detect Linux distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        export ZSH_DISTRO="$ID"
    fi
else
    export ZSH_PLATFORM="unknown"
fi
# Python - pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PIPENV_PYTHON="$PYENV_ROOT/shims/python"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
if command -v pyenv 1>/dev/null 2>&1; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  export PYENV_SHELL=zsh
  eval "$(pyenv init -)"
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  mkdir -p ~/.zinit
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### -----------------------------
### PATH and Environment Setup
### -----------------------------
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.n/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$HOME/go/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
# Node - NVM (lazy loading for faster startup)
export NVM_DIR="$HOME/.nvm"

# Lazy load NVM - only load when needed
nvm() {
  unfunction nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Auto-load nvm when using node/npm commands
node() {
  unfunction node
  nvm use default >/dev/null
  node "$@"
}

npm() {
  unfunction npm
  nvm use default >/dev/null
  npm "$@"
}

npx() {
  unfunction npx
  nvm use default >/dev/null
  npx "$@"
}

# Node - n
export N_PREFIX="$HOME/.n"

# make brew installed gcc ahead of macOS native symlinked gcc (only uncomment this when running in macos and building emacs)
# export PATH="$(brew --prefix gcc)/bin:$PATH"
# export CC=gcc-13 
### -----------------------------
### Aliases
### -----------------------------
alias v="nvim"
alias e="$EMACS"
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias ..="cd .."

# Modern CLI tool aliases with platform-specific handling
if command -v eza &>/dev/null; then
  alias ls="eza --color=auto --icons"
  alias ll="eza -l --color=auto --icons --git"
  alias la="eza -la --color=auto --icons --git"
  alias lt="eza --tree --color=auto --icons"
  alias l="eza -F --color=auto --icons"
else
  # Fallback to enhanced ls if eza is not available
  alias ls="ls --color=auto"
  alias ll="ls -lh --color=auto"
  alias la="ls -lah --color=auto"
  alias l="ls -CF --color=auto"
fi

# Handle bat vs batcat (Ubuntu uses batcat)
if command -v batcat &>/dev/null; then
  alias bat="batcat"
  alias cat="batcat --style=plain --paging=never"
  alias less="batcat --style=plain"
elif command -v bat &>/dev/null; then
  alias cat="bat --style=plain --paging=never"
  alias less="bat --style=plain"
fi

# Handle fd vs fdfind (Ubuntu uses fdfind)
if command -v fdfind &>/dev/null; then
  alias fd="fdfind"
elif command -v fd &>/dev/null; then
  # fd is available with correct name
  :
fi

# Better grep with ripgrep
if command -v rg &>/dev/null; then
  alias grep="rg --color=auto"
fi

# Quick directory navigation
alias ...="cd ../.."
alias ....="cd ../../.."

# Useful functions
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *.xz)        unxz "$1"        ;;
      *.lzma)      unlzma "$1"      ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quick file search
ff() {
  find . -type f -name "*$1*"
}

# Directory shortcuts
hash -d config="$XDG_CONFIG_HOME"
hash -d dots="$HOME/DotFiles"

# Bootstrap function to check for missing tools
zsh_bootstrap() {
    local missing_tools=()
    local tools=("fzf" "ripgrep" "git")
    local optional_tools=("eza" "zoxide")
    
    echo "🔍 Checking for essential tools..."
    
    # Check essential tools
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            case "$tool" in
                "ripgrep")
                    if ! command -v rg &>/dev/null; then
                        missing_tools+=("$tool")
                    fi
                    ;;
                *)
                    missing_tools+=("$tool")
                    ;;
            esac
        fi
    done
    
    # Check bat/batcat
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        missing_tools+=("bat")
    fi
    
    # Check fd/fdfind
    if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
        missing_tools+=("fd")
    fi
    
    # Report missing essential tools
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "❌ Missing essential tools: ${missing_tools[*]}"
        echo
        echo "To install all tools automatically, run:"
        echo "  cd $HOME/DotFiles/zsh && ./install.sh"
        echo
        return 1
    fi
    
    # Check optional tools
    local missing_optional=()
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_optional+=("$tool")
        fi
    done
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        echo "⚠️  Optional tools not found: ${missing_optional[*]}"
        echo "These tools provide enhanced functionality but are not required."
        echo
    fi
    
    echo "✅ Essential tools check completed!"
    return 0
}

# Check for missing tools on startup (but only once per session)
if [[ -z "$ZSH_BOOTSTRAP_CHECKED" ]]; then
    export ZSH_BOOTSTRAP_CHECKED=1
    
    # Only run bootstrap check if we're in an interactive shell
    if [[ $- == *i* ]]; then
        # Run the check in the background to avoid slowing down shell startup
        {
            sleep 1
            if ! zsh_bootstrap >/dev/null 2>&1; then
                echo
                echo "💡 Tip: Run 'zsh_bootstrap' to check for missing tools, or 'cd ~/DotFiles/zsh && ./install.sh' to install them automatically."
                echo
            fi
        } &
    fi
fi

### -----------------------------
### Completion System
### -----------------------------
autoload -Uz compinit
autoload -U bashcompinit && bashcompinit

# Smart completion caching
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Completion styles
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# fzf-tab configuration with cross-platform tool support
zstyle ':fzf-tab:complete:cd:*' fzf-preview '(eza -1 --color=always $realpath || ls -1 --color=always $realpath) 2>/dev/null'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview '(eza -1 --color=always $realpath || ls -1 --color=always $realpath) 2>/dev/null'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'

# Git command previews (fallback to cat if bat/batcat not available)
if command -v delta &>/dev/null; then
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
  zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'case "$group" in "commit tag") git show --color=always $word ;; *) git show --color=always $word | delta ;; esac'
  zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'case "$group" in "modified file") git diff $word | delta ;; "recent commit object name") git show --color=always $word | delta ;; *) git log --color=always $word ;; esac'
else
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always $word'
  zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word'
  zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --color=always $word'
fi

zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'

# Git help preview (with bat/batcat fallback)
if command -v batcat &>/dev/null; then
  zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | batcat -plman --color=always'
elif command -v bat &>/dev/null; then
  zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'
else
  zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | cat'
fi

### -----------------------------
### Plugin Manager - zinit
### -----------------------------
source ~/.zinit/bin/zinit.zsh

### -----------------------------
### Plugins via zinit
### -----------------------------
# Autosuggestions
zinit light zsh-users/zsh-autosuggestions

# Fast syntax highlighting (better performance than zsh-syntax-highlighting)
zinit light zdharma-continuum/fast-syntax-highlighting

# Fast completions
zinit light zsh-users/zsh-completions

# fzf-tab: replace default completion with fzf (must load after compinit but before autosuggestions)
zinit light Aloxaf/fzf-tab

# Powerup history search
zinit light zdharma-continuum/history-search-multi-word

# Interactive git commands with fzf
zinit light wfxr/forgit

# Auto-close brackets and quotes
zinit light hlissner/zsh-autopair

# p10k prompt
zinit light romkatv/powerlevel10k

# vi mode
export ZVM_VI_ESCAPE_BINDKEY=jk
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# Fzf integration (if installed)
if command -v fzf &>/dev/null; then
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# Zoxide integration (smart cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="z"
fi

### -----------------------------
### Other Options
### -----------------------------
setopt autocd                   # cd by typing dir name
setopt correct                  # correct mistyped commands
setopt nocaseglob               # case-insensitive globbing
setopt extended_glob            # extended globbing
setopt hist_ignore_dups         # no duplicate history entries
setopt hist_ignore_all_dups     # remove older duplicates
setopt hist_ignore_space        # ignore commands starting with space
setopt hist_verify              # confirm history expansions
setopt inc_append_history       # append to history incrementally
setopt share_history            # share history across terminals
setopt hist_reduce_blanks       # remove superfluous blanks

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# Key bindings
bindkey '^R' history-incremental-search-backward
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^H' backward-kill-word     # Ctrl+Backspace
bindkey '^[[3;5~' kill-word         # Ctrl+Delete

# Accept autosuggestion with Ctrl+Space
bindkey '^ ' autosuggest-accept

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Load Angular CLI autocompletion (only if angular is available)
if command -v ng &>/dev/null; then
  source <(ng completion script)
fi

# Ensure npm global bin is in PATH (avoid duplicates)
[[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]] && export PATH="$HOME/.npm-global/bin:$PATH"

# Performance: compile .zshrc for faster loading
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc
fi
