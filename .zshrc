### -----------------------------
### PATH and Environment Setup
### -----------------------------
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.n/bin:$PATH"

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
if command -v pyenv 1>/dev/null 2>&1; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  export PYENV_SHELL=zsh
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi
# Emacs
export EMACS="/Applications/Emacs.app/Contents/MacOS/Emacs"

### -----------------------------
### Aliases
### -----------------------------
alias v="nvim"
alias e="$EMACS"
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias ..="cd .."

### -----------------------------
### Prompt - Starship
### -----------------------------
eval "$(starship init zsh)"

### -----------------------------
### Plugin Manager - zinit
### -----------------------------
if [[ ! -f "$HOME/.zinit/bin/zinit.zsh" ]]; then
  mkdir -p ~/.zinit
  git clone https://github.com/zdharma-continuum/zinit.git ~/.zinit/bin
fi
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
