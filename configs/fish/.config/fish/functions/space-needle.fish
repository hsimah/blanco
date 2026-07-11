function space-needle --wraps='ssh adminhabl@space-needle -i ~/.ssh/blanco_ed25519 -p 2002' --description 'alias space-needle ssh adminhabl@space-needle -i ~/.ssh/blanco_ed25519 -p 2002'
    ssh adminhabl@space-needle -i ~/.ssh/blanco_ed25519 -p 2002 $argv
end
