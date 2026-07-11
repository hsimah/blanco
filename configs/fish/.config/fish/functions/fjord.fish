function fjord --wraps='ssh adminhabl@fjord -i ~/.ssh/blanco_ed25519' --description 'alias fjord ssh adminhabl@fjord -i ~/.ssh/blanco_ed25519'
    ssh adminhabl@fjord -i ~/.ssh/blanco_ed25519 $argv
end
