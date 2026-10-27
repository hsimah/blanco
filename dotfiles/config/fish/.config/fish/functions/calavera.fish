function calavera --wraps=ssh --description 'ssh calavera — attaches to the persistent "loft" tmux session'
    __loft_ssh calavera adminhabl@calavera -i ~/.ssh/blanco_ed25519 -- $argv
end
