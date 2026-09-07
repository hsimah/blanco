function viking --wraps=ssh --description 'ssh viking — attaches to the persistent "loft" tmux session'
    __loft_ssh adminhabl@viking -i ~/.ssh/blanco_ed25519 -- $argv
end
