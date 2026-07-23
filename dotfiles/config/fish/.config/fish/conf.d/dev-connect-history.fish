function __dedupe_dev_connect --on-event fish_postexec --description 'Keep only the most recent `dev connect` entry in history'
    string match -q -- 'dev connect*' $argv[1]; or return
    set -l entries (history search --prefix 'dev connect' --null | string split0)
    for entry in $entries[2..-1]
        history delete --exact --case-sensitive -- "$entry"
    end
end
