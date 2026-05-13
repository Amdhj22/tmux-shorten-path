#!/usr/bin/env zsh
# Print a shortened form of an absolute path. See README for the behaviour
# of each strategy.
#
# Env:
#   SHORTEN_PATH_STRATEGY        truncate_to_unique | truncate_from_right
#                                 | truncate_to_last | none
#   SHORTEN_PATH_SEG_THRESHOLD   only truncate when len > N  (default 5)
#   SHORTEN_PATH_SEG_LENGTH      chars per non-last segment  (default 1)
#   SHORTEN_PATH_MARKERS         space-separated marker filenames

emulate -L zsh
setopt no_unset

local raw="${1:-$PWD}"
local strategy="${SHORTEN_PATH_STRATEGY:-truncate_to_unique}"

# ---- strategy: none --------------------------------------------------------
# Just collapse HOME to ~.
if [[ "$strategy" == "none" ]]; then
  print -r -- "${raw/#$HOME/~}"
  exit 0
fi

# ---- strategy: truncate_to_last -------------------------------------------
# Only the basename. The root path "/" is preserved verbatim.
if [[ "$strategy" == "truncate_to_last" ]]; then
  if [[ "$raw" == "/" ]]; then
    print -r -- "/"
  else
    print -r -- "${raw:t}"
  fi
  exit 0
fi

# ---- strategy: truncate_from_right ----------------------------------------
# Each non-last component → first N chars. Hidden dirs get +1.
if [[ "$strategy" == "truncate_from_right" ]]; then
  local seg_length="${SHORTEN_PATH_SEG_LENGTH:-1}"
  local display="${raw/#$HOME/~}"
  local -a parts
  parts=("${(@s:/:)display}")
  local n=${#parts[@]} i c short result=""
  for ((i = 1; i <= n; i++)); do
    c="${parts[i]}"
    [[ -z "$c" ]] && continue
    if (( i == n )); then
      short="$c"
    elif [[ "$c" == "~" ]]; then
      short="~"
    elif [[ "$c" == .?* ]]; then
      short="${c:0:$((seg_length + 1))}"
    else
      short="${c:0:$seg_length}"
    fi
    if [[ -z "$result" ]]; then
      result="$short"
    else
      result="${result}/${short}"
    fi
  done
  if [[ "$raw" == /* && "${result:0:1}" != "/" && "${result:0:1}" != "~" ]]; then
    result="/$result"
  fi
  print -r -- "$result"
  exit 0
fi

# ---- strategy: truncate_to_unique (default) -------------------------------
# Folder-marker anchor + shortest unique prefix among siblings.

local -a markers
if [[ -n "${SHORTEN_PATH_MARKERS:-}" ]]; then
  markers=(${(s: :)SHORTEN_PATH_MARKERS})
else
  markers=(.shorten_folder_marker .git .hg .svn .bzr CVS _darcs
           Cargo.toml go.mod package.json composer.json stack.yaml
           CMakeCache.txt .terraform)
fi

local -a abs_parts
abs_parts=("${(@s:/:)raw}")

local anchor_idx=0 i m prefix=""
for ((i = 1; i <= ${#abs_parts[@]}; i++)); do
  local comp="${abs_parts[i]}"
  [[ -z "$comp" ]] && continue
  prefix="${prefix}/${comp}"
  # Skip HOME and its ancestors — anchor must be strictly below HOME (or
  # outside HOME entirely) to be useful for path shortening.
  [[ "$prefix" == "$HOME" || "$HOME" == "$prefix"/* ]] && continue
  for m in $markers; do
    if [[ -e "${prefix}/${m}" ]]; then
      anchor_idx=$i
      break 2
    fi
  done
done

local display="${raw/#$HOME/~}"
local -a parts
parts=("${(@s:/:)display}")
local n=${#parts[@]}

local -a home_parts
home_parts=("${(@s:/:)HOME}")
local home_depth=0 h
for h in $home_parts; do [[ -n "$h" ]] && ((home_depth++)); done

local display_anchor=0
if [[ "$raw" == "$HOME"* ]]; then
  if (( anchor_idx <= home_depth + 1 )); then
    (( anchor_idx > 0 )) && display_anchor=1
  else
    display_anchor=$(( anchor_idx - home_depth ))
  fi
else
  display_anchor=$anchor_idx
fi

local cutoff
if (( display_anchor > 0 )); then
  cutoff=$display_anchor
else
  cutoff=$n
fi

local seg_threshold="${SHORTEN_PATH_SEG_THRESHOLD:-5}"

# Shortest unique prefix of $1 among entries of parent dir $2, suffixed with
# "..". If no shorter unique prefix exists, returns $1 unchanged.
_unique_prefix() {
  local seg="$1" parent="$2"
  local seg_len=${#seg} plen pfx sib
  local -a sibs
  sibs=("$parent"/*(N:t) "$parent"/.*(N:t))
  for ((plen = 1; plen < seg_len; plen++)); do
    pfx="${seg:0:$plen}"
    local unique=1
    for sib in $sibs; do
      [[ "$sib" == "$seg" || "$sib" == "." || "$sib" == ".." ]] && continue
      if [[ "$sib" == "$pfx"* ]]; then unique=0; break; fi
    done
    (( unique )) && { print -r -- "${pfx}.."; return; }
  done
  print -r -- "$seg"
}

local result="" abs_path="" c short parent
for ((i = 1; i <= n; i++)); do
  c="${parts[i]}"
  [[ -z "$c" ]] && continue

  if [[ -z "$abs_path" ]]; then
    parent="/"
  else
    parent="$abs_path"
  fi
  if [[ "$c" == "~" ]]; then
    abs_path="$HOME"
  elif [[ -z "$abs_path" ]]; then
    abs_path="/$c"
  else
    abs_path="$abs_path/$c"
  fi

  if (( i < cutoff )); then
    if [[ "$c" == "~" ]]; then
      short="~"
    elif [[ "$c" == .?* ]]; then
      short="${c:0:2}"
    else
      short="${c:0:1}"
    fi
  elif (( i == n )); then
    short="$c"
  elif (( i > cutoff )) && (( ${#c} > seg_threshold )); then
    short=$(_unique_prefix "$c" "$parent")
  else
    short="$c"
  fi

  if [[ -z "$result" ]]; then
    result="$short"
  else
    result="${result}/${short}"
  fi
done

if [[ "$raw" == /* && "${result:0:1}" != "/" && "${result:0:1}" != "~" ]]; then
  result="/$result"
fi

print -r -- "$result"
