#! /bin/sh

set -eu

initial_prompt='What to name this screenshot?'
file_exists_prompt="That file already exists! $initial_prompt"

prompt="$initial_prompt"

# Get current filename from stdin
read current_filename

default_filename=$(date)

while true; do
	new_filename="$(echo "$default_filename" | dmenu -p "$prompt")"

	# race condition, but idc
	if [ -e "$new_filename" ]; then
		prompt="$file_exists_prompt"
		continue
	fi

	mv_error=$(mv "$current_filename" "$new_filename" 2>&1)
	if [ $? -eq 0 ]; then
		break
	fi

	prompt="Error: '$mv_error' $initial_prompt"
done
