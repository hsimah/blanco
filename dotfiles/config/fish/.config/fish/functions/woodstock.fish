function woodstock --wraps=ssh --description 'ssh woodstock — attaches to the persistent "loft" tmux session'
    __loft_ssh adminhabl@woodstock -i ~/.ssh/blanco_ed25519 -- $argv
end
