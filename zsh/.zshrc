# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────────
# Environment
# ─────────────────────────────────────────────
export TERM=xterm-256color
export EDITOR="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.n/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"

# Python (pyenv)
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"  # if you use pyenv-virtualenv

# Node (lazy-load NVM)
export NVM_DIR="$HOME/.nvm"
nvm()  { unfunction nvm;   [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"; nvm "$@"; }
node() { unfunction node;  nvm use default >/dev/null; node "$@"; }
npm()  { unfunction npm;   nvm use default >/dev/null; npm "$@"; }
npx()  { unfunction npx;   nvm use default >/dev/null; npx "$@"; }

# Compiler paths (macOS Homebrew GCC)
# export LIBRARY_PATH="/opt/homebrew/lib/gcc/current:$LIBRARY_PATH"
# export CC="/opt/homebrew/bin/gcc-15"
# export CXX="/opt/homebrew/bin/g++-15"

# ─────────────────────────────────────────────
# Aliases
# ─────────────────────────────────────────────
alias v="nvim"
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
# alias cd="z"  # Moved to zoxide initialization block (line 124)

# Modern tools with graceful fallback
if command -v eza &>/dev/null; then
  alias ls="eza --color=auto --icons"
  alias ll="eza -l --git --icons"
  alias la="eza -la --git --icons"
  alias lt="eza --tree --icons"
else
  alias ls="ls --color=auto"
  alias ll="ls -lh --color=auto"
  alias la="ls -lah --color=auto"
fi

if command -v batcat &>/dev/null; then
  alias cat="batcat --style=plain --paging=never"
elif command -v bat &>/dev/null; then
  alias cat="bat --style=plain --paging=never"
fi

if command -v rg &>/dev/null; then
  alias grep="rg --color=auto"
fi

command -v fdfind &>/dev/null && alias fd="fdfind"

# ─────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() {
  [[ -f "$1" ]] || { echo "Not a file: $1"; return; }
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;; *.tar.gz) tar xzf "$1" ;;
    *.bz2) bunzip2 "$1" ;; *.rar) unrar x "$1" ;;
    *.gz) gunzip "$1" ;; *.tar) tar xf "$1" ;;
    *.tbz2) tar xjf "$1" ;; *.tgz) tar xzf "$1" ;;
    *.zip) unzip "$1" ;; *.7z) 7z x "$1" ;;
    *.xz) unxz "$1" ;; *.lzma) unlzma "$1" ;;
    *) echo "Unsupported archive: $1" ;;
  esac
}
ff() { find . -type f -name "*$1*"; }

hash -d config="$XDG_CONFIG_HOME"
hash -d dots="$HOME/DotFiles"

# ─────────────────────────────────────────────
# Plugin Manager (zinit)
# ─────────────────────────────────────────────
if [[ ! -f ~/.zinit/bin/zinit.zsh ]]; then
  mkdir -p ~/.zinit/bin && git clone https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
fi
source ~/.zinit/bin/zinit.zsh

# ─────────────────────────────────────────────
# Plugins
# ─────────────────────────────────────────────
autoload -Uz compinit bashcompinit && bashcompinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi

# Core completions & fuzzy completion
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'

# Autosuggestions & history
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/history-search-multi-word
zinit light zsh-users/zsh-history-substring-search

# Visual enhancements
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light romkatv/powerlevel10k
zinit light wfxr/forgit
zinit light hlissner/zsh-autopair

# Vi mode (after autosuggestions)
export ZVM_VI_ESCAPE_BINDKEY=jk
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# Tool integrations
command -v fzf &>/dev/null && [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

command -v ng &>/dev/null && source <(ng completion script)

# ─────────────────────────────────────────────
# Shell Behavior
# ─────────────────────────────────────────────
setopt autocd correct nocaseglob extended_glob
setopt hist_ignore_all_dups hist_ignore_space hist_verify inc_append_history share_history hist_reduce_blanks
HISTFILE=~/.zsh_history; HISTSIZE=50000; SAVEHIST=50000

# Accept autosuggestion with Ctrl+Space
bindkey '^ ' autosuggest-accept

# ─────────────────────────────────────────────
# Prompt
# ─────────────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ─────────────────────────────────────────────
# Performance
# ─────────────────────────────────────────────
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc
fi

FPATH="$HOME/.docker/completions:$FPATH"
autoload -Uz compinit
compinit

# ─────────────────────────────────────────────
# zoxide (must be initialized at the very end so it overrides any prior cd)
# ─────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="z"
fi
