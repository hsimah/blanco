function fjord --wraps=ssh --description 'ssh fjord — attaches to the persistent "loft" tmux session'
    __loft_ssh fjord adminhabl@fjord -i ~/.ssh/blanco_ed25519 -- $argv
end
