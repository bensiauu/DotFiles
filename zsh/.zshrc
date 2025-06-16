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
export EDITOR="emacs -nw"
# Node - NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Node - n
export N_PREFIX="$HOME/.n"

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

# make brew installed gcc ahead of macOS native symlinked gcc
export PATH="$(brew --prefix gcc)/bin:$PATH"
export CC=gcc-13 
### -----------------------------
### Aliases
### -----------------------------
alias v="nvim"
alias e="$EMACS"
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias ..="cd .."

### -----------------------------
### Plugin Manager - zinit
### -----------------------------
source ~/.zinit/bin/zinit.zsh

### -----------------------------
### Plugins via zinit
### -----------------------------
# Autosuggestions
zinit light zsh-users/zsh-autosuggestions

# Syntax Highlighting
zinit light zsh-users/zsh-syntax-highlighting

# Fast completions
zinit light zsh-users/zsh-completions

# Powerup history search
zinit light zdharma-continuum/history-search-multi-word

# p10k prompt
zinit light romkatv/powerlevel10k

# Fzf integration (if installed)
if command -v fzf &>/dev/null; then
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

### -----------------------------
### Other Options
### -----------------------------
setopt autocd             # cd by typing dir name
setopt correct            # correct mistyped commands
setopt nocaseglob         # case-insensitive globbing
setopt extended_glob      # extended globbing
setopt hist_ignore_dups   # no duplicate history entries
setopt share_history      # share history across terminals

bindkey '^R' history-incremental-search-backward

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
