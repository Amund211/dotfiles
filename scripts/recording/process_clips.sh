#!/bin/bash
# Version 1.3 2026-10-18
#
# History of the cut command:
#   < 1.1       ffmpeg -i IN -map 0 -c copy -ss S -to E OUT
#               Output seeking: audio cut at S, video waits for next keyframe (1-2s without picture).
#   1.1 2023-01-25  ffmpeg -copyts -ss S -to E -i IN -map 0 -c copy OUT
#               Input seeking fixed the A/V gap, but -copyts kept replay timestamps (clip starts at S).
#   1.2 2026-10-13  ffmpeg -ss S -to E -i IN -map 0 -c copy -avoid_negative_ts make_zero OUT
#               Starts at last keyframe before S, timestamps from 0.
#   1.3 2026-10-18  Clip keeps the container of the replay (mkv or mp4), and keeps mp4 track names.

set -eu

# Prefix of all files that will be processed
REPLAY_PREFIX="${1:-Replay}"

REPLAY_DIR="$HOME/recording"
CLIP_DIR="$HOME/recording/clips"
PROCESSED_DIR="$HOME/recording/.processed_clips"

mkdir -p "$CLIP_DIR"
mkdir -p "$PROCESSED_DIR"

set -- "$REPLAY_DIR/$REPLAY_PREFIX"*
if [ ! -e "$1" ]; then
	echo "No replays matching $REPLAY_DIR/$REPLAY_PREFIX*" >&2
	exit 1
fi
amount="$#"
processed=0

categories="Categories (folders):
$(find "$CLIP_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -not -name 'bestof' -not -name 'converted' -not -name 'tmp' -printf '\t%f\n' | sort)"

for replay_file in "$@"; do
	clear
	if [ -n "${last_command:-}" ]; then
		echo
		echo "$last_command"
	fi
	echo "$categories"
	echo "Now processing $(basename "$replay_file") $((processed + 1))/$amount"
	ext="${replay_file##*.}"
	# OBS mp4 files store track names in a 'name' tag, which ffmpeg only writes back from 'title'
	meta=()
	i=0
	while IFS= read -r name; do
		[ -n "$name" ] && meta+=("-metadata:s:$i" "title=$name")
		i=$((i + 1))
	done < <(ffprobe -v error -show_entries stream_tags=name -of csv=p=0 "$replay_file")
	vlc "$replay_file" >/dev/null 2>/dev/null &
	vlc_pid="$!"

	keep_clip=''
	while [ "$keep_clip" != 'y' ] && [ "$keep_clip" != 'n' ]; do
		echo 'Keep this clip? (y/n)                     '
		read -r keep_clip
	done

	# Get start and end time until valid
	while [ "$keep_clip" = 'y' ]; do
		echo 'Clip starts at the last keyframe before this time (up to 2s early) '
		echo 'Start at? (Leave blank for start of clip) '
		read -r start_time
		if [ -z "$start_time" ]; then
			from_timestamp=''
		else
			from_timestamp="-ss $start_time"
		fi

		echo 'End at? (Leave blank for end of clip)     '
		read -r end_time
		if [ -z "$end_time" ]; then
			to_timestamp=''
		else
			to_timestamp="-to $end_time"
		fi

		# Get filename until unique
		while true; do
			echo "Name of clip (don't include .$ext) "
			read -r clip_filename
			clip_file="$CLIP_DIR/$clip_filename.$ext"

			case "$clip_filename" in
			'')
				echo "Name can't be empty!" >&2
				continue
				;;
			*.mkv | *.mp4)
				echo "Don't include the extension!" >&2
				continue
				;;
			esac
			# Also check the other container, so a name is never used twice
			if [ -f "$CLIP_DIR/$clip_filename.mkv" ] || [ -f "$CLIP_DIR/$clip_filename.mp4" ]; then
				echo "File already exists" >&2
				continue
			fi
			break
		done

		# Input seeking with stream copy starts the clip on a keyframe; no -copyts so it starts at 0
		if ffmpeg -loglevel error $from_timestamp $to_timestamp -i "$replay_file" -map 0 -c copy "${meta[@]}" -avoid_negative_ts make_zero "$clip_file"; then
			last_command="ffmpeg -loglevel error $from_timestamp $to_timestamp -i '$replay_file' -map 0 -c copy ${meta[*]} -avoid_negative_ts make_zero '$clip_file'"
			touch --reference="$replay_file" "$clip_file"
			break
		fi
		rm -f "$clip_file"
	done


	kill -INT "$vlc_pid" || true
	# Make sure the user closed this vlc instance before starting a new one
	wait "$vlc_pid" || true

	# Mark the replay as processed
	mv "$replay_file" "$PROCESSED_DIR"
	# cp "$replay_file" "$PROCESSED_DIR"

	processed="$((processed + 1))"
done
