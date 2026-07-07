#!/usr/bin/env bash
# claude-i3-notify.sh <waiting|done|clear|log>
#
# Claude Code hook dispatcher. Records the calling session's state in a per-session
# file so the i3blocks [claude_status] blocklet can render it. The file is tagged
# with the terminal's X11 window id ($WINDOWID, exported by alacritty and inherited
# by hooks) so the blocklet can resolve which workspace the session lives on.
#
#   waiting -> orange dot  (Notification of a "needs you" type: permission_prompt,
#                           agent_needs_input, elicitation_dialog)
#   done    -> green dot   (Stop / StopFailure: turn finished)
#   clear   -> no dot      (UserPromptSubmit / PostToolUse / PostToolUseFailure /
#                           SessionEnd: working or gone)
#   log     -> no state change; append the notification message to notifications.log
#              (wired to a catch-all Notification hook so we can spot any notification
#              type we don't yet classify — see the type matchers in settings.json).
set -uo pipefail

mode=${1:?usage: claude-i3-notify.sh <waiting|done|clear|log>}
dir=${XDG_RUNTIME_DIR:-/tmp}/claude-i3
mkdir -p "$dir"

raw=$(cat)

if [ "$mode" = log ]; then
  msg=$(printf '%s' "$raw" | jq -r '.message // "-"' 2>/dev/null) || msg="-"
  # NOTE: this log is not readable from inside the Claude Code sandbox (different /run view).
  printf '%s\t%s\n' "$(date '+%F %T')" "$msg" >>"$dir/notifications.log"
  exit 0
fi

sid=$(printf '%s' "$raw" | jq -r '.session_id // empty' 2>/dev/null) || sid=""
[ -n "$sid" ] || exit 0

f=$dir/$sid
changed=
case $mode in
  clear)
    [ -e "$f" ] && { rm -f "$f"; changed=1; } ;;
  waiting|done)
    new="$mode ${WINDOWID:-0}"
    old=$(cat "$f" 2>/dev/null) || old=
    [ "$old" != "$new" ] && { printf '%s\n' "$new" >"$f"; changed=1; } ;;
  *) exit 0 ;;
esac

# Only redraw i3blocks when state actually changed, so the frequent clear calls
# (every PostToolUse) don't spam refreshes when nothing was pending.
[ -n "$changed" ] && pkill -RTMIN+12 i3blocks 2>/dev/null
exit 0
