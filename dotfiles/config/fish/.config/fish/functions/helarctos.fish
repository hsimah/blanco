function helarctos --wraps=ssh --description 'ssh helarctos — attaches to the persistent "loft" tmux session'
    __loft_ssh adminhabl@helarctos -i ~/.ssh/blanco_ed25519 -- $argv
end
