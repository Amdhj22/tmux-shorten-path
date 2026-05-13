#!/usr/bin/env bash
# Setup script for the vhs demo recording.
#
# Strategy:
#   1. Build a fake HOME with a small dummy project tree (no real dotfiles).
#   2. Spin up an isolated tmux server (-L tsp_demo).
#   3. Source the user's real tmux.conf for theme/style/key-bindings.
#   4. Strip away anything that would (a) leak real absolute paths or
#      (b) render broken placeholders when third-party plugins are missing.
#   5. Pre-create multiple windows at different cwds so the demo opens
#      with a non-trivial workspace already in place.
#   6. Load the shorten_path plugin so #{shorten_path} placeholders resolve.

set -euo pipefail

REAL_HOME=$HOME
DEMO_DIR=/tmp/tsp-demo
SOCK=tsp_demo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# --- 1) fake project tree -------------------------------------------------
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR/myproject/server/api/middleware/handlers"
mkdir -p "$DEMO_DIR/myproject/server/api/migrations"
mkdir -p "$DEMO_DIR/myproject/server/db"
mkdir -p "$DEMO_DIR/myproject/client"
mkdir -p "$DEMO_DIR/myproject/bin"
( cd "$DEMO_DIR/myproject" && git init -q )

# macOS: /tmp is a symlink to /private/tmp. tmux's pane_current_path uses the
# canonical form, so HOME must match canonical too.
DEMO=$(cd "$DEMO_DIR" && pwd -P)

# --- 2) isolated tmux server + first window (at fake HOME) ---------------
tmux -L "$SOCK" kill-server 2>/dev/null || true

HOME="$DEMO" tmux -L "$SOCK" new-session -d -s demo \
  -c "$DEMO" \
  "PROMPT='%F{cyan}%~%f %# ' zsh -d -f"

# --- 3) source the user's tmux.conf for visual continuity -----------------
tmux -L "$SOCK" source-file "$REAL_HOME/dotfiles/tmux.conf" 2>/dev/null || true

# --- 4) sanitize for the recording ----------------------------------------
# (a) hooks that fire real scripts in ~/dotfiles/bin
tmux -L "$SOCK" set-hook -gu client-attached
tmux -L "$SOCK" set-hook -gu client-focus-in
tmux -L "$SOCK" set-hook -gu pane-focus-in
tmux -L "$SOCK" set-hook -gu session-window-changed

# (b) status-right depends on tmux-cpu / tmux-battery / tmux-prefix-highlight
tmux -L "$SOCK" set-option -g status-right ""

# (c) fast status redraw so cd's reflect immediately
tmux -L "$SOCK" set-option -g status-interval 1

# (d) every new pane / window uses the minimal zsh
tmux -L "$SOCK" set-option -g default-command "PROMPT='%F{cyan}%~%f %# ' zsh -d -f"

# --- 5) pre-create additional windows at varied cwds ----------------------
HOME="$DEMO" tmux -L "$SOCK" new-window -t demo -c "$DEMO/myproject/server/api"
HOME="$DEMO" tmux -L "$SOCK" new-window -t demo -c "$DEMO/myproject/client"

# Focus back on the first window — demo starts at ~
tmux -L "$SOCK" select-window -t demo:0

# --- 6) load shorten_path plugin -----------------------------------------
tmux -L "$SOCK" run-shell "$SCRIPT_DIR/../shorten_path.tmux"
