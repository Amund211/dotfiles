#!/usr/bin/env bash
# claude-status-block.sh — i3blocks blocklet (markup=pango).
#
# Renders one colored dot per active Claude Code session, tagged with the number
# of the workspace it lives on:
#   orange  = waiting on you (permission prompt / idle input)
#   green   = finished responding
#
# Green dots auto-dismiss once you focus that workspace ("seen"). Entries whose
# window has gone away are pruned. State is written by claude-i3-notify.sh.

dir=${XDG_RUNTIME_DIR:-/tmp}/claude-i3
shopt -s nullglob
files=("$dir"/*)
# Nothing tracked -> empty block; skip the tree query entirely when idle.
[ ${#files[@]} -gt 0 ] || { echo; exit 0; }

tree=$(i3-msg -t get_tree 2>/dev/null) || { echo; exit 0; }

# Currently focused workspace number.
focused=$(i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused).num // empty')

# Map every managed window id -> its workspace number ("<winid> <num>" per line).
map=$(printf '%s' "$tree" | jq -r '
  .. | objects | select(.type=="workspace") | .num as $n
  | (.. | objects | select(.window != null) | .window)
  | "\(.) \($n)"' 2>/dev/null)

WAIT="#FFA500"; DONE="#33CC33"
segs=()
for f in "${files[@]}"; do
  read -r st wid < "$f" 2>/dev/null || { rm -f "$f"; continue; }
  [ -n "${wid:-}" ] || { rm -f "$f"; continue; }
  ws=$(awk -v w="$wid" '$1==w{print $2; exit}' <<<"$map")
  [ -n "$ws" ] || { rm -f "$f"; continue; }              # window gone -> prune
  if [ "$st" = done ] && [ "$ws" = "$focused" ]; then
    rm -f "$f"; continue                                 # seen -> dismiss
  fi
  case $st in
    waiting) col=$WAIT ;;
    done)    col=$DONE ;;
    *)       continue ;;
  esac
  segs+=("$ws|<span foreground=\"$col\">●</span>$ws")
done

[ ${#segs[@]} -gt 0 ] || { echo; exit 0; }
body=$(printf '%s\n' "${segs[@]}" | sort -n -t'|' -k1,1 | cut -d'|' -f2- | paste -sd' ' -)
echo "cc $body"
