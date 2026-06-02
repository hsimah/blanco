function fjord --wraps='ssh hsimah@fjord -i ~/.ssh/blanco_ed25519' --description 'alias fjord ssh hsimah@fjord -i ~/.ssh/blanco_ed25519'
    ssh hsimah@fjord -i ~/.ssh/blanco_ed25519 $argv
end
