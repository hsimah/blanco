function fish_greeting
    command -q fastfetch; or return

    set -l position left
    if test "$COLUMNS" -lt 100
        set position top
    end
    command fastfetch --logo-position $position
end
