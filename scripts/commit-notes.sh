#!/bin/sh

set -eu

if [ ! -d "$HOME/git/notes" ]; then
	echo 'Could not find notes directory!' >&2
	exit 1
fi

cd "$HOME/git/notes"
git add .
git commit -m "Notes $(date --iso-8601=seconds)

$(git status --short)"
git push
