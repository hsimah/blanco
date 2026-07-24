function __dedupe_dev_connect --on-event fish_postexec --description 'Collapse `dev connect` history entries that differ only in the `-y` token'
    set -l cmd $argv[1]
    string match -q -- 'dev connect*' $cmd; or return
    string match -qr -- '-y[= ]+\S+' $cmd; or return
    set -l key (string replace -ar -- '-y[= ]+\S+' '-y <y>' $cmd)
    set -l seen 0
    for entry in (history search --prefix 'dev connect' --null | string split0)
        test (string replace -ar -- '-y[= ]+\S+' '-y <y>' $entry) = "$key"; or continue
        if test $seen -eq 0
            set seen 1
            continue
        end
        history delete --exact --case-sensitive -- "$entry"
    end
end
