function space-needle --wraps=ssh --description 'ssh space-needle — attaches to the persistent "loft" tmux session'
    __loft_ssh adminhabl@space-needle -i ~/.ssh/blanco_ed25519 -p 2002 -- $argv
end
