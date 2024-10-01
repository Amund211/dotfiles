#!/bin/sh

set -eu

audiosuffix='face'
videosuffix='notes'

audiofiletype='mp4'
videofiletype='mp4'

base="${1:-}"

if [ -z "$base" ]; then
	echo Must provide a basename >&2
	exit 1
fi

if [ "$base" = '-h' ] || [ "$base" = '--help' ]; then
	echo "How to use:

Use the network tab to find the m3u8 files for the camera- and lecture notes streams.
Pass the link to the m3u8 files to youtube-dl or ffmpeg, and save the output to
'prefix'face.mp4 and 'prefix'notes.mp4.
This way you can simply run ./mix_panopto_streams.sh and tab complete the prefix." >&2
	exit 1
fi

audioname="$base$audiosuffix.$audiofiletype"
videoname="$base$videosuffix.$videofiletype"

ffmpeg -i "$videoname" -i "$audioname" -c copy -map 0:v:0 -map 1:a:0 "${base}mixed.mp4"
