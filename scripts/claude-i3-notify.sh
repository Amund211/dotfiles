#!/usr/bin/env bash
# claude-i3-notify.sh <waiting|done|clear|log>
#
# Claude Code hook dispatcher. Records the calling session's state in a per-session
# file so the i3blocks [claude_status] blocklet can render it.
#
# State file format: "<mode> <ws> <windowid>"
#   The workspace number is resolved here (from $WINDOWID, exported by alacritty and
#   inherited by hooks) and stored, so the blocklet can render without querying i3
#   unless a green dot needs a focused-workspace check.
#
#   waiting -> orange dot  (Notification of a "needs you" type: permission_prompt,
#                           agent_needs_input, elicitation_dialog)
#   done    -> green dot   (Stop / StopFailure: turn finished)
#   clear   -> no dot      (UserPromptSubmit / PostToolUse / PostToolUseFailure /
#                           SessionEnd: working or gone)
#   log     -> no state change; append the notification message to notifications.log
#              (catch-all Notification hook, to spot unclassified notification types).
#
# The same orange/green dot is also painted onto the session window's i3 title bar via
# a per-window `title_format` override, so a workspace holding several sessions (e.g. the
# stacked pr-review terminals on ws9/ws10) shows which one wants you, not just that
# something on that workspace does. `%title` keeps claude's own live title, so nothing
# races over WM_NAME - which is also why nothing else may set title_format on these
# windows: the clear path resets it to plain "%title".
#
# Title dots are tracked in $dir/titles/<sid> — deliberately NOT the state file, which
# the blocklet deletes when a green dot auto-dismisses on workspace focus. A title dot
# must outlive that: focusing ws9 shouldn't erase which of eight windows finished. It
# clears when the session is actually used again (clear) — and the marker means the
# frequent clear calls cost one file test, not an i3-msg.
set -euo pipefail

mode=${1:?usage: claude-i3-notify.sh <waiting|done|clear|log>}
dir=${XDG_RUNTIME_DIR:-/tmp}/claude-i3
titles=$dir/titles
mkdir -p "$titles" || exit 0

# Same colors as the [claude_status] blocklet.
WAIT_COLOR="#FFA500"; DONE_COLOR="#33CC33"

# Pango attribute values must be single-quoted: a nested double quote ends i3's
# command string and the rest parses as a second, bogus command.
set_title_dot() {
  i3-msg "[id=$2] title_format \"<span foreground='$1'>●</span> %title\"" >/dev/null 2>&1 || true
}

clear_title_dot() {
  i3-msg "[id=$1] title_format \"%title\"" >/dev/null 2>&1 || true
}

raw=$(cat)

if [ "$mode" = log ]; then
  # Record the notification type + message so we can spot any type not yet handled
  # by the matchers in settings.json. Wired to a catch-all Notification hook.
  ntype=$(printf '%s' "$raw" | jq -r '.notification_type // .type // "?"' 2>/dev/null || true)
  msg=$(printf '%s' "$raw" | jq -r '.message // "-"' 2>/dev/null || true)
  printf '%s\t%s\t%s\n' "$(date '+%F %T')" "${ntype:-?}" "${msg:--}" >>"$dir/notifications.log" || true
  exit 0
fi

sid=$(printf '%s' "$raw" | jq -r '.session_id // empty' 2>/dev/null || true)
[ -n "$sid" ] || exit 0

f=$dir/$sid
marker=$titles/$sid
changed=
case $mode in
  clear)
    if [ -e "$marker" ]; then
      read -r _ wid <"$marker" 2>/dev/null || wid=
      [ -n "${wid:-}" ] && clear_title_dot "$wid"
      rm -f "$marker"
    fi
    if [ -e "$f" ]; then rm -f "$f"; changed=1; fi
    ;;
  waiting|done)
    # Resolve the workspace of this session's window, once, and store it.
    ws=$(i3-msg -t get_tree 2>/dev/null | jq -r --argjson w "${WINDOWID:-0}" '
      [.. | objects | select(.type=="workspace")]
      | map(select([.. | objects | .window?] | index($w)))
      | .[0].num // empty' 2>/dev/null || true)
    new="$mode ${ws:-?} ${WINDOWID:-0}"
    old=$(cat "$f" 2>/dev/null || true)
    if [ "$old" != "$new" ]; then printf '%s\n' "$new" >"$f"; changed=1; fi

    if [ "${WINDOWID:-0}" != 0 ]; then
      want="$mode ${WINDOWID}"
      if [ "$(cat "$marker" 2>/dev/null || true)" != "$want" ]; then
        case $mode in
          waiting) set_title_dot "$WAIT_COLOR" "$WINDOWID" ;;
          done)    set_title_dot "$DONE_COLOR" "$WINDOWID" ;;
        esac
        printf '%s\n' "$want" >"$marker"
      fi
    fi
    ;;
esac

# Redraw i3blocks only when the state changed, so the frequent clear calls
# (every PostToolUse) don't spam refreshes when nothing was pending.
if [ -n "$changed" ]; then pkill -RTMIN+12 i3blocks 2>/dev/null || true; fi
exit 0
