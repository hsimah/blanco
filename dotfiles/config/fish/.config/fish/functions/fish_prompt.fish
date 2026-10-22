function fish_prompt
    set -l last_command_status $status
    set -l current_directory (prompt_pwd)
    set -l prompt_status_color
    if test $last_command_status -eq 0
        set prompt_status_color green
    else
        set prompt_status_color red
    end
    set_color $fish_color_cwd
    echo -n "$current_directory"
    set_color normal
    if git rev-parse --git-dir > /dev/null 2>&1
        set -l git_branch (git symbolic-ref --short HEAD 2>/dev/null; or git describe --tags --exact-match 2>/dev/null; or echo "HEAD")
        set -l git_commit_short (git rev-parse --short HEAD 2>/dev/null)
        set -l git_dirty ""
        if not git diff --quiet 2>/dev/null
            set git_dirty "*"
        end
        if not git diff --cached --quiet 2>/dev/null
            set git_dirty "$git_dirty+"
        end
        set_color yellow
        echo -n " ("
        set_color cyan
        echo -n "$git_branch"
        set_color normal
        echo -n "@"
        set_color magenta
        echo -n "$git_commit_short"
        if test -n "$git_dirty"
            set_color red
            echo -n "$git_dirty"
        end
        set_color yellow
        echo -n ")"
        set_color normal
    end
    echo -n " "
    set_color $prompt_status_color
    echo -n "❯ "
    set_color normal
end
