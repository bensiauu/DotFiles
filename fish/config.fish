#if status is-interactive
#    oh-my-posh init fish --config ~/.config/fish/.poshthemes/theme.json | source
#end

starship init fish | source

function fish_user_key_bindings
    bind \t complete --do-complete
end


set -x PATH $PATH $HOME/go/bin
set -x CXXFLAGS "-std=c++11"
set -x PATH $PATH $HOME/flutter/bin/
set -x PATH /opt/homebrew/opt/ruby/bin $PATH
set -x PATH $PATH $HOME/.emacs.d/bin/
