#!/usr/bin/env bash
# tmux-shorten-path: TPM entry script.
# Interpolates the placeholder #{shorten_path} in tmux status/format options
# with a shell command call to scripts/shorten_path.sh.

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT="$CURRENT_DIR/scripts/shorten_path.sh"

PLACEHOLDER='#{shorten_path}'

get_tmux_option() {
  local opt=$1
  local default=$2
  local val
  val=$(tmux show-options -gqv "$opt" 2>/dev/null)
  if [ -z "$val" ]; then
    val=$(tmux show-options -wgqv "$opt" 2>/dev/null)
  fi
  if [ -z "$val" ]; then
    val="$default"
  fi
  echo "$val"
}

build_command() {
  local env_prefix=""
  local strategy seg_threshold seg_length markers
  strategy=$(get_tmux_option "@shorten_path_strategy" "")
  seg_threshold=$(get_tmux_option "@shorten_path_seg_threshold" "")
  seg_length=$(get_tmux_option "@shorten_path_seg_length" "")
  markers=$(get_tmux_option "@shorten_path_markers" "")
  [ -n "$strategy" ]      && env_prefix+="SHORTEN_PATH_STRATEGY=$strategy "
  [ -n "$seg_threshold" ] && env_prefix+="SHORTEN_PATH_SEG_THRESHOLD=$seg_threshold "
  [ -n "$seg_length" ]    && env_prefix+="SHORTEN_PATH_SEG_LENGTH=$seg_length "
  [ -n "$markers" ]       && env_prefix+="SHORTEN_PATH_MARKERS='$markers' "
  printf '#(%s%s "#{pane_current_path}")' "$env_prefix" "$SCRIPT"
}

CMD=$(build_command)

interpolate_option() {
  local opt=$1
  local scope=$2  # "" for session, "-w" for window
  local value
  value=$(tmux show-options $scope -gqv "$opt" 2>/dev/null)
  [ -z "$value" ] && return
  case "$value" in
    *"$PLACEHOLDER"*) ;;
    *) return ;;
  esac
  local new=${value//${PLACEHOLDER}/${CMD}}
  tmux set-option $scope -gq "$opt" "$new"
}

interpolate_option "status-left" ""
interpolate_option "status-right" ""
interpolate_option "window-status-format" "-w"
interpolate_option "window-status-current-format" "-w"
interpolate_option "pane-border-format" "-w"

exit 0
