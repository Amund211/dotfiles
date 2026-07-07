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
set -euo pipefail

mode=${1:?usage: claude-i3-notify.sh <waiting|done|clear|log>}
dir=${XDG_RUNTIME_DIR:-/tmp}/claude-i3
mkdir -p "$dir" || exit 0

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
changed=
case $mode in
  clear)
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
    ;;
esac

# Redraw i3blocks only when the state changed, so the frequent clear calls
# (every PostToolUse) don't spam refreshes when nothing was pending.
if [ -n "$changed" ]; then pkill -RTMIN+12 i3blocks 2>/dev/null || true; fi
exit 0
