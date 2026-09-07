function __loft_ssh --description 'ssh to a loft host, attaching to its persistent tmux session'
    # Usage: __loft_ssh <ssh opts...> -- $argv
    # With no user args: attach to (or create) the "loft" tmux session on the host.
    # With user args: run them directly, no tmux — keeps `space-needle sudo docker ps`
    # and friends working exactly as before.

    set -l split (contains -i -- -- $argv)
    set -l opts $argv[1..(math $split - 1)]
    set -l rest $argv[(math $split + 1)..-1]

    if test (count $rest) -gt 0
        ssh $opts $rest
    else
        # Falls back to a plain login shell on hosts where setup.sh has not
        # installed tmux yet.
        ssh -t $opts 'command -v tmux >/dev/null && exec tmux new-session -A -s loft || exec $SHELL -l'
    end
end
