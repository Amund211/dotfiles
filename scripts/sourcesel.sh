#! /usr/bin/env bash

# Prompt user to select an audio source using dmenu
# Sets selected source as default, and switches all
# source-outputs to use that source using pactl


INPUT="$(pactl list short sources | \
	awk -F "\t" "{print \$2}" | dmenu -i -p "Select a source")"

pactl set-default-source "$INPUT" >/dev/null 2>&1

#sed "s/alsa_output.//" | \
#awk -v len=40 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }'


for recording in $(pactl list short source-outputs | awk "{print \$1}")
do
	pactl move-source-output "$recording" "$INPUT" >/dev/null 2>&1
done
