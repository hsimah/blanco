function __loft_ssh --description 'ssh to a loft host, attaching to its persistent tmux session'
    # Usage: __loft_ssh <ssh opts...> -- [command...]

    set -l split (contains -i -- -- $argv)
    set -l opts $argv[1..(math $split - 1)]
    set -l rest $argv[(math $split + 1)..-1]

    if test (count $rest) -gt 0
        ssh $opts $rest
    else
        ssh -t $opts 'command -v tmux >/dev/null && exec tmux new-session -A -s loft || exec $SHELL -l'
    end
end
