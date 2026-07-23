# niri keybindings

Reference for the `binds { … }` block in
`configs/niri/.config/niri/config.kdl`. Keep in sync when binds change.

`Mod` = `Super` on a TTY session (what these machines run); all keys below use
`Mod` for consistency even where the config writes `Super`. Press
`Mod+Shift+/` in-session to pull up niri's own hotkey overlay.

## Applications & system

| Key | Action |
|-----|--------|
| `Mod+T` | Open a terminal (kitty) |
| `Mod+Space` | App launcher (fuzzel) |
| `Mod+Alt+L` | Lock screen (noctalia) |
| `Mod+BackSpace` | Lock screen (noctalia) |
| `Mod+Alt+S` | Toggle screen reader (orca) |

## Windows & focus

| Key | Action |
|-----|--------|
| `Mod+H` | Focus column left |
| `Mod+L` | Focus column right |
| `Mod+J` | Focus window / workspace down |
| `Mod+K` | Focus window / workspace up |
| `Mod+Home` / `Mod+B` | Focus first column |
| `Mod+End` / `Mod+N` | Focus last column |
| `Mod+Ctrl+H` | Move column left |
| `Mod+Ctrl+L` | Move column right |
| `Mod+Ctrl+J` | Move window down / to workspace down |
| `Mod+Ctrl+K` | Move window up / to workspace up |
| `Mod+Ctrl+Home` / `Mod+Ctrl+B` | Move column to first |
| `Mod+Ctrl+End` / `Mod+Ctrl+N` | Move column to last |
| `Mod+Q` | Close window |

## Columns & window layout

| Key | Action |
|-----|--------|
| `Mod+R` | Cycle preset column widths |
| `Mod+Shift+R` | Cycle preset column widths (reverse) |
| `Mod+Ctrl+R` | Reset window height |
| `Mod+Ctrl+Shift+R` | Cycle preset window heights |
| `Mod+Minus` / `Mod+Equal` | Column width −10% / +10% |
| `Mod+Shift+Minus` / `Mod+Shift+Equal` | Window height −10% / +10% |
| `Mod+F` | Maximize column |
| `Mod+Shift+F` | Fullscreen window |
| `Mod+M` | Maximize window to edges |
| `Mod+Ctrl+F` | Expand column to available width |
| `Mod+C` | Center column |
| `Mod+Ctrl+C` | Center all visible columns |
| `Mod+V` | Toggle window floating |
| `Mod+Shift+V` | Switch focus between floating and tiling |
| `Mod+W` | Toggle tabbed column display |
| `Mod+BracketLeft` / `Mod+BracketRight` | Consume/expel window left / right |
| `Mod+Comma` | Consume window into column |
| `Mod+Period` | Expel window from column |
| `Mod+O` | Toggle overview |

## Workspaces

| Key | Action |
|-----|--------|
| `Mod+1`…`Mod+9` | Focus workspace 1–9 |
| `Mod+Ctrl+1`…`Mod+Ctrl+9` | Move column to workspace 1–9 |
| `Mod+Page_Down` / `Mod+Page_Up` | Focus workspace down / up |
| `Mod+Ctrl+Page_Down` / `Mod+Ctrl+Page_Up` | Move column to workspace down / up |
| `Mod+Shift+Page_Down` / `Mod+Shift+Page_Up` | Move workspace down / up |
| `Mod+Shift+J` / `Mod+Shift+K` | Move workspace down / up |

## Monitors

| Key | Action |
|-----|--------|
| `Mod+Shift+Left` / `Mod+Shift+H` | Focus monitor left |
| `Mod+Shift+Right` / `Mod+Shift+L` | Focus monitor right |
| `Mod+Shift+Up` / `Mod+Shift+Down` | Focus monitor up / down |
| `Mod+Shift+Ctrl+H` / `Mod+Shift+Ctrl+Left` | Move column to monitor left |
| `Mod+Shift+Ctrl+L` / `Mod+Shift+Ctrl+Right` | Move column to monitor right |
| `Mod+Shift+Ctrl+K` / `Mod+Shift+Ctrl+Up` | Move column to monitor up |
| `Mod+Shift+Ctrl+J` / `Mod+Shift+Ctrl+Down` | Move column to monitor down |
| `Mod+Shift+Ctrl+Home` / `Mod+Shift+Ctrl+B` | Move workspace to monitor left |
| `Mod+Shift+Ctrl+End` / `Mod+Shift+Ctrl+N` | Move workspace to monitor right |
| `Mod+Ctrl+Y` | Gather all workspaces onto external monitor (keep `personal` on laptop) — runs `niri-gather-workspaces` |

## Screenshots & recording

| Key | Action |
|-----|--------|
| `Print` | Screenshot (interactive) |
| `Alt+Print` | Screenshot focused window |
| `Ctrl+Print` | Toggle screen recording (noctalia) |

## Session

| Key | Action |
|-----|--------|
| `Mod+Shift+Slash` | Show hotkey overlay |
| `Mod+Escape` | Toggle keyboard-shortcuts inhibitor |
| `Mod+Shift+P` | Power off monitors |
| `Mod+Shift+E` | Quit niri (with confirmation) |
| `Ctrl+Alt+Delete` | Quit niri (with confirmation) |

## Mouse wheel (with `Mod`)

| Key | Action |
|-----|--------|
| `Mod+WheelDown` / `Mod+WheelUp` | Focus workspace down / up |
| `Mod+WheelRight` / `Mod+WheelLeft` | Focus column right / left |
| `Mod+Shift+WheelDown` / `Mod+Shift+WheelUp` | Focus column right / left |
| `Mod+Ctrl+WheelDown` / `Mod+Ctrl+WheelUp` | Move column to workspace down / up |
| `Mod+Ctrl+WheelRight` / `Mod+Ctrl+WheelLeft` | Move column right / left |
| `Mod+Ctrl+Shift+WheelDown` / `Mod+Ctrl+Shift+WheelUp` | Move column right / left |

## Hardware keys

| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volume up / down |
| `XF86AudioMute` | Mute output |
| `XF86AudioMicMute` | Mute microphone |
| `XF86AudioPlay` / `XF86AudioStop` | Play-pause / stop (playerctl) |
| `XF86AudioPrev` / `XF86AudioNext` | Previous / next track |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Brightness up / down |

## Non-keybind triggers

- **Lid close** → lock screen (noctalia), via `switch-events`.
