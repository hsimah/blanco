function viking --wraps='ssh adminhabl@viking -i ~/.ssh/blanco_ed25519' --description 'alias viking ssh adminhabl@viking -i ~/.ssh/blanco_ed25519'
    ssh adminhabl@viking -i ~/.ssh/blanco_ed25519 $argv
end
