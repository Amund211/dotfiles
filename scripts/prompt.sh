#! /usr/bin/bash
# Creates a dmenu prompt labeled with $1 to execute command $2
# ./prompt "Shutdown???" "shutdown -h now"

[ "$(echo -e "No\nYes" | dmenu -i -p "$1")" = "Yes" ] && $2
