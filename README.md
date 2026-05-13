# tmux-shorten-path

p10k-style path shortening for tmux status bars — folder marker anchors + `truncate_to_unique`.

```
/Users/foo/dotfiles/config/nvim/playground/asdfads
                  ↓
~/dotfiles/c../nvim/pla../asdfads
   anchor↑     ↑     ↑
              long segments → shortest unique prefix among siblings
```

## Why

Powerlevel10k displays current path with two clever rules:

1. **Folder anchors** — when a directory contains `.git`, `package.json`, `go.mod`, etc., the path *from that directory onwards* is kept full (so you always see where you are inside the project).
2. **`truncate_to_unique`** — segments before/around the anchor are shortened to the shortest prefix that doesn't collide with sibling directories, so `playground` becomes `pla..` only if `plugin` exists alongside it; otherwise just `p..`.

tmux has no built-in equivalent. This plugin brings the same logic to your status line.

## Install

Using [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'Amdhj22/tmux-shorten-path'
```

Then `prefix + I` to install.

Manual install:

```sh
git clone https://github.com/Amdhj22/tmux-shorten-path ~/.tmux/plugins/tmux-shorten-path
echo "run-shell ~/.tmux/plugins/tmux-shorten-path/shorten_path.tmux" >> ~/.tmux.conf
```

## Usage

Use `#{shorten_path}` anywhere in `status-left`, `status-right`, `window-status-format`, `window-status-current-format`, or `pane-border-format`. The plugin rewrites it to a shell call at load time:

```tmux
set -g status-left "#{shorten_path} | #S #I:#P "
```

Reload tmux config — the placeholder is replaced with the current pane's shortened path.

## Options

Set before the `run-shell` (or `set -g @plugin`) line.

| Option                            | Default                                                          | Description                                                                 |
| --------------------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `@shorten_path_strategy`          | `truncate_to_unique`                                             | One of `truncate_to_unique`, `truncate_from_right`, `truncate_to_last`, `none`. |
| `@shorten_path_seg_threshold`     | `5`                                                              | (`truncate_to_unique`) Only truncate segments longer than this.             |
| `@shorten_path_seg_length`        | `1`                                                              | (`truncate_from_right`) Chars kept per non-last segment. Hidden dirs get +1. |
| `@shorten_path_markers`           | `.git .hg .svn .bzr CVS _darcs Cargo.toml go.mod package.json composer.json stack.yaml CMakeCache.txt .terraform .shorten_folder_marker` | (`truncate_to_unique`) Files that mark a directory as an anchor. Space-separated. |

Example:

```tmux
set -g @shorten_path_strategy truncate_to_unique
set -g @shorten_path_seg_threshold 3
set -g @shorten_path_markers ".git Makefile"
set -g @plugin 'Amdhj22/tmux-shorten-path'
```

To declare *any* directory as an anchor, drop a `.shorten_folder_marker` file in it:

```sh
touch ~/some/long/path/.shorten_folder_marker
```

## Strategies

All strategies collapse `$HOME` to `~`.

| Strategy              | What it does                                                                                                |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `truncate_to_unique`  | (default) Folder-marker anchor + shortest unique prefix among siblings. See *How it works* below.            |
| `truncate_from_right` | Every non-last component → first N chars (`@shorten_path_seg_length`). Hidden dirs get +1.                   |
| `truncate_to_last`    | Only the basename. `/` stays as `/`.                                                                         |
| `none`                | As-is (with `$HOME` collapsed to `~`).                                                                       |

Same path, different strategies:

```
input: ~/dotfiles/config/nvim/playground/asdfads

truncate_to_unique     →  ~/dotfiles/c../nvim/pla../asdfads
truncate_from_right    →  ~/d/c/n/p/asdfads
truncate_from_right    →  ~/do/co/nv/pl/asdfads   (seg_length=2)
truncate_to_last       →  asdfads
none                   →  ~/dotfiles/config/nvim/playground/asdfads
```

## How it works (truncate_to_unique)

The algorithm runs on every status redraw:

1. **Find anchor.** Walk components from root, looking for a directory containing any marker file. The shallowest match wins. `$HOME` and its ancestors are never considered anchors (otherwise a single `package.json` in your home would defeat the whole purpose).
2. **Before the anchor:** truncate each component to 1 char (2 for hidden dirs starting with `.`).
3. **The anchor:** kept full.
4. **After the anchor (middle segments):** if length > threshold, replace with the shortest prefix that doesn't collide with any sibling entry, suffixed with `..`.
5. **Last (current) segment:** always kept full.
6. **No anchor:** only the last component is kept full; everything else is one char.

## Examples

Assume `~/dotfiles/.git` exists (so `~/dotfiles` is the anchor) and `~/dotfiles/config/nvim/` contains both `playground/` and `plugin/`:

| Full path                                             | Shortened (`truncate_to_unique`)       |
| ----------------------------------------------------- | -------------------------------------- |
| `~/dotfiles`                                          | `~/dotfiles`                           |
| `~/dotfiles/bin`                                      | `~/dotfiles/bin`                       |
| `~/dotfiles/config/ghostty`                           | `~/dotfiles/c../ghostty`               |
| `~/dotfiles/config/nvim`                              | `~/dotfiles/c../nvim`                  |
| `~/dotfiles/config/nvim/playground/asdfads`           | `~/dotfiles/c../nvim/pla../asdfads`    |
| `~/.config/nvim/lua/plugins` (no anchor)              | `~/.c/n/l/plugins`                     |
| `/usr/local/share/zsh/site-functions` (no anchor)     | `/u/l/s/z/site-functions`              |

## Performance

One `ls`-style glob per middle segment per redraw. With tmux's default `status-interval` (15s) and typical paths (2-3 middle segments), overhead is negligible.

If you have very deep paths in a network mount, consider raising `status-interval`.

## Requirements

- tmux 3.0+
- zsh (for the script — does not require zsh as your shell)

## License

MIT
