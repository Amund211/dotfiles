#!/bin/sh

set -eu

FOCUS='focus'
OPERATIONS='operations'

is_focus() {
	current_time="$(date +%H:%M)"
	if [[ "$current_time" > '07:00' ]] && [[ "$current_time" < '14:00' ]]; then
		return 0
	fi
	return 1
}

state=operations

if is_focus; then
	state=$FOCUS
fi

while true; do
	if [[ $state == $OPERATIONS ]] && is_focus; then
		state=$FOCUS
		dunstify 'Focus time has started' 'Please close slack' --timeout=300000
	elif [[ $state == $FOCUS ]] && ! is_focus; then
		state=$OPERATIONS
		dunstify 'Focus time has ended' 'Slack has been opened' --timeout=60000
		chromium 'https://app.slack.com/client/T3SMJ1JQP' &>/dev/null &
		disown -a
	fi
	sleep 60
done
