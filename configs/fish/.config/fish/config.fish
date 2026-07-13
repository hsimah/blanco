test -f ~/.config/fish/local.fish
    and source ~/.config/fish/local.fish

set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"

fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
