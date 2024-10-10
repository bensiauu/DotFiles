if status is-interactive
    oh-my-posh init fish --config ~/.config/fish/.poshthemes/theme.json | source
end

set -x PATH $PATH $HOME/go/bin
set -x CXXFLAGS "-std=c++11"
