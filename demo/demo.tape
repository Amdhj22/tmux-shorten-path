# vhs tape for tmux-shorten-path README demo.
#
# Run from repo root:
#   vhs demo/demo.tape
# Produces demo/demo.gif.
#
# Requires: vhs, tmux, zsh, git. The 'D2Coding ligature' font is referenced
# below to match the author's Ghostty setup — if you don't have it installed
# vhs falls back to a default monospace.

Output demo/demo.gif

Set Shell bash
Set FontFamily "D2Coding ligature"
Set FontSize 13
Set Width 1200
Set Height 400
Set Padding 20
Set PlaybackSpeed 1.0

# rbr theme — extracted from ~/dotfiles/config/ghostty/themes/rbr
Set Theme { "name": "rbr", "black": "#05091a", "red": "#e84a55", "green": "#9cc080", "yellow": "#f5c842", "blue": "#82a0d8", "magenta": "#a8a8b0", "cyan": "#f5c842", "white": "#c8d0e8", "brightBlack": "#3a4466", "brightRed": "#f56570", "brightGreen": "#b8d49e", "brightYellow": "#ffd84d", "brightBlue": "#a4bde8", "brightMagenta": "#c8c8d0", "brightCyan": "#ffd84d", "brightWhite": "#e8ecf5", "background": "#0a1128", "foreground": "#c8d0e8", "selection": "#1f2a52", "cursor": "#ffd84d" }

# --- setup (hidden from the recording) ---
Hide
Type "bash demo/setup.sh && clear"
Enter
Sleep 500ms

Type "HOME=/tmp/tsp-demo tmux -L tsp_demo attach -t demo"
Enter
Sleep 1s
Show

# --- demo opens at ~ with 3 pre-made windows already in the status bar ---
Sleep 2s

# walk into the project
Type "cd ~/myproject"
Enter
Sleep 2s

Type "cd server/api/middleware/handlers"
Enter
Sleep 2500ms

# --- switch to the pre-made windows ---
# next window (prefix + n) → window 1 at ~/myproject/server/api
Ctrl+a
Type "n"
Sleep 2500ms

# next window → window 2 at ~/myproject/client
Ctrl+a
Type "n"
Sleep 2500ms

# previous window (prefix + p) → back to window 1
Ctrl+a
Type "p"
Sleep 2s

# --- split horizontal, work in two panes at once ---
Ctrl+a
Type "|"
Sleep 1500ms

Type "cd ~/myproject/server/db"
Enter
Sleep 2500ms

# jump back to the left pane (vim-tmux-navigator binding)
Ctrl+h
Sleep 2s
