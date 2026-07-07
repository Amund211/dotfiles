#!/usr/bin/env bash
# claude-status-block.sh — i3blocks blocklet (markup=pango).
#
# Renders one colored dot per active Claude Code session, tagged with its workspace:
#   orange = waiting on you (permission / input);  green = finished.
# Green dots auto-dismiss once you focus their workspace.
#
# Dead sessions (terminal killed without a graceful exit) are pruned via a cheap
# per-window xdotool existence check — no full-tree query.
#
# Perf: the i3 tree is never queried; get_workspaces runs ONLY when a green dot is
# present (to read the focused workspace). Orange dots render straight from the
# workspace number recorded in the state file by claude-i3-notify.sh.

dir=${XDG_RUNTIME_DIR:-/tmp}/claude-i3
shopt -s nullglob
WAIT="#FFA500"; DONE="#33CC33"

# Load per-session state files ("<mode> <ws> <windowid>"); skip the *.log files
# that live in the same dir (else they get read as bogus sessions).
states=(); wss=(); paths=()
have_done=0
for f in "$dir"/*; do
  case ${f##*/} in *.log) continue ;; esac
  [ -f "$f" ] || continue
  read -r st ws wid < "$f" 2>/dev/null || continue
  [ -n "${st:-}" ] || continue
  # Prune sessions whose terminal window is gone (an ungraceful exit that never
  # fired SessionEnd; graceful exits clear themselves). Cheap per-window X check,
  # so we still never query the full i3 tree.
  if [ -z "${wid:-}" ] || ! xdotool getwindowname "$wid" >/dev/null 2>&1; then
    rm -f "$f"; continue
  fi
  states+=("$st"); wss+=("${ws:-?}"); paths+=("$f")
  [ "$st" = done ] && have_done=1
done

[ ${#states[@]} -gt 0 ] || { echo; exit 0; }

# Only touch i3 when a green dot might need dismissing.
focused=""
if [ "$have_done" = 1 ]; then
  focused=$(i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused).num // empty' 2>/dev/null) || focused=""
fi

segs=()
for i in "${!states[@]}"; do
  st=${states[$i]}; ws=${wss[$i]}
  if [ "$st" = done ]; then
    if [ -n "$focused" ] && [ "$ws" = "$focused" ]; then rm -f "${paths[$i]}"; continue; fi
    col=$DONE
  else
    col=$WAIT
  fi
  segs+=("$ws|<span foreground=\"$col\">●</span>$ws")
done

[ ${#segs[@]} -gt 0 ] || { echo; exit 0; }
printf '%s\n' "${segs[@]}" | sort -n -t'|' -k1,1 | cut -d'|' -f2- | paste -sd' ' -
