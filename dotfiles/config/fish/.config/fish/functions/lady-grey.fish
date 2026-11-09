function lady-grey --wraps=ssh --description 'ssh lady-grey — attaches to the persistent "loft" tmux session'
    __loft_ssh lady-grey adminhabl@lady-grey -i ~/.ssh/blanco_ed25519 -- $argv
end
