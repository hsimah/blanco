if status is-login
    and test (tty) = /dev/tty1
    and not set -q NIRI_SOCKET
    exec niri-session
end
