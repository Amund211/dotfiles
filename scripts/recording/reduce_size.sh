#!/bin/bash
# Usage: reduce_size.sh FILE TARGET_MB
# Two-pass x264 encode of FILE to about TARGET_MB, with only the first audio track (the Mix).
# Output: discorded/<FILE without extension>-<TARGET_MB>mB.mp4

set -eu

input="$1"
target_video_size_MB="$2"
output="discorded/${input%.*}-${target_video_size_MB}mB.mp4"
mkdir -p "$(dirname "$output")"

# Audio is re-encoded at a fixed rate: mkv files store no per-stream bitrate to copy from
target_audio_bitrate_kbit_s=160
# Format duration: mkv files have no per-stream duration
origin_duration_s="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$input")"
target_video_bitrate_kbit_s=$(
	awk \
		-v size="$target_video_size_MB" \
		-v duration="$origin_duration_s" \
		-v audio_rate="$target_audio_bitrate_kbit_s" \
		'BEGIN { print int(( size * 8192.0 ) / ( 1.048576 * duration ) - audio_rate) }'
)

ffmpeg \
	-y \
	-i "$input" \
	-map 0:v:0 \
	-c:v libx264 \
	-b:v "$target_video_bitrate_kbit_s"k \
	-pass 1 \
	-an \
	-f mp4 \
	/dev/null &&
	ffmpeg \
		-i "$input" \
		-map 0:v:0 -map 0:a:0 \
		-c:v libx264 \
		-b:v "$target_video_bitrate_kbit_s"k \
		-pass 2 \
		-c:a aac -b:a "$target_audio_bitrate_kbit_s"k \
		"$output"
