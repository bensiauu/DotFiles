#if status is-interactive
#    oh-my-posh init fish --config ~/.config/fish/.poshthemes/theme.json | source
#end


set -g fish_greeting
set -Ux PYENV_ROOT $HOME/.pyenv
set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths
pyenv init - | source
starship init fish | source

function tmux
    command tmux -f ~/.config/tmux.conf $argv
end

if [ "$INSIDE_EMACS" = vterm ]
    function clear
        vterm_printf "51;Evterm-clear-scrollback"
        tput clear
    end
end

# Add Ruby, Go, Flutter, Emacs, and other custom directories only once
set -x PATH $HOME/go/bin $PATH
set -x PATH $HOME/flutter/bin $PATH
set -x PATH $HOME/.config/emacs/bin $PATH
set -x PATH $HOME/.npm-global/bin $PATH
set -x PATH /opt/homebrew/opt/postgresql@15/bin $PATH


# Optionally, set other environment variables like CXXFLAGS
set -x CXXFLAGS "-std=c++11"
