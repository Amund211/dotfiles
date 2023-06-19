#! /usr/bin/sh

# Prompt user to select an audio sink using dmenu
# Sets selected sink as default, and switches all
# sink-inputs to use that sink using pactl


OUTPUT="$(pactl list short sinks | \
	awk -F "\t" "{print \$2}" | dmenu -i -p "Select a sink")"

pactl set-default-sink "$OUTPUT" >/dev/null 2>&1

#sed "s/alsa_output.//" | \
#awk -v len=40 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }'


for playing in $(pactl list short sink-inputs | awk "{print \$1}")
do
	pactl move-sink-input "$playing" "$OUTPUT" >/dev/null 2>&1
done
