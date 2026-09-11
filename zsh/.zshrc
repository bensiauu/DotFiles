# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────────
# Herdr auto-start — launch (or attach to) the persistent session for
# interactive terminals. Skips: non-interactive shells, a shell already inside
# herdr, the VS Code integrated terminal, and when HERDR_DISABLE_AUTOSTART=1 is
# exported. Exiting/detaching herdr drops you back to a plain shell.
#   • one-off plain shell:   HERDR_DISABLE_AUTOSTART=1 zsh
#   • disable permanently:   export HERDR_DISABLE_AUTOSTART=1  (above this line)
# ─────────────────────────────────────────────
if [[ -o interactive && -z "${HERDR_ENV:-}" \
      && -z "${HERDR_DISABLE_AUTOSTART:-}" \
      && "$TERM_PROGRAM" != "vscode" && -z "${VSCODE_INJECTION:-}" ]] \
   && command -v herdr &>/dev/null; then
  exec herdr
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

# Node (lazy-load NVM)
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
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

ss() {
  mkdir -p ~/tmp
  powershell.exe -NoProfile -Command \
    "Add-Type -Assembly System.Windows.Forms; Add-Type -Assembly System.Drawing; \$img=[System.Windows.Forms.Clipboard]::GetImage(); if(-not \$img){\$data=[System.Windows.Forms.Clipboard]::GetDataObject(); if(\$data -and \$data.GetDataPresent('PNG')){\$stream=\$data.GetData('PNG'); \$img=[System.Drawing.Image]::FromStream(\$stream)}}; if(\$img){New-Item -ItemType Directory -Force -Path 'C:\Temp'|Out-Null; \$img.Save('C:\Temp\ss.png'); Write-Host 'OK'} else {Write-Host 'NO_IMAGE'; exit 1}"
  if [ $? -eq 0 ]; then
    cp /mnt/c/Temp/ss.png ~/tmp/ss.png 2>/dev/null && echo "~/tmp/ss.png updated"
  else
    echo "No image in clipboard"
  fi
}

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

# opencode
export PATH=/home/bensiauu/.opencode/bin:$PATH

# secret
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

export LANG=en_US.UTF.8
export LC_ALL=en_US.UTF-8
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# bun completions
[ -s "/home/bensiauu/.bun/_bun" ] && source "/home/bensiauu/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
