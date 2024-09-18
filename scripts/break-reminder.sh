#!/bin/sh

set -u

interval="${1:-$((30 * 60))}"

while true; do
	sleep "$interval"
	dunstify \
		'60 second break' \
		'Look at something far away' \
		--timeout=65000 \
		--icon=/usr/share/icons/hicolor/scalable/apps/nm-device-wired.svg \
		-h string:bgcolor:#447744
done
