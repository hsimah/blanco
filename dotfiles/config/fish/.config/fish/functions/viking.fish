function viking --wraps=ssh --description 'ssh viking — attaches to the persistent "loft" tmux session'
    __loft_ssh viking adminhabl@100.119.43.53 -i ~/.ssh/blanco_ed25519 -- $argv
end
