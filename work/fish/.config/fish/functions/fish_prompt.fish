function fish_prompt
    set -l last_command_status $status
    
    # Get current directory with ~ for home
    set -l current_directory (prompt_pwd)
    
    # Status color based on last command
    set -l prompt_status_color
    if test $last_command_status -eq 0
        set prompt_status_color green
    else
        set prompt_status_color red
    end
    
    # Start building prompt
    set_color $fish_color_cwd
    echo -n "$current_directory"
    set_color normal
    
    # Git information
    if git rev-parse --git-dir > /dev/null 2>&1
        # Get current branch or HEAD state
        set -l git_branch (git symbolic-ref --short HEAD 2>/dev/null; or git describe --tags --exact-match 2>/dev/null; or echo "HEAD")
        
        # Get short commit hash
        set -l git_commit_short (git rev-parse --short HEAD 2>/dev/null)
        
        # Check for dirty working directory
        set -l git_dirty ""
        if not git diff --quiet 2>/dev/null
            set git_dirty "*"
        end
        
        # Check for staged changes
        if not git diff --cached --quiet 2>/dev/null
            set git_dirty "$git_dirty+"
        end
        
        # Display git info
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
    
    # Final prompt character
    echo -n " "
    set_color $prompt_status_color
    echo -n "❯ "
    set_color normal
end
