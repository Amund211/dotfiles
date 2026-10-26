#!/bin/sh

set -eu

input_file="${1:-}"

if [ -z "$input_file" ]; then
	echo "No file provided!" >&2
	exit 1
fi

if [ ! -d "tmp" ]; then
	echo "Must have a tmp dir!" >&2
	exit 1
fi

if [ ! -d "converted" ]; then
	echo "Must have a converted dir!" >&2
	exit 1
fi

input_dir="$(dirname "$input_file")"
input_base="$(basename "$input_file" '.mkv')"

input_prefix="${input_dir}/${input_base}"

mkdir -p "tmp/${input_dir}"
mkdir -p "converted/${input_dir}"

desktop_audio_file="tmp/${input_prefix}_desktop_audio.aac"
raw_mic_audio_file="tmp/${input_prefix}_raw_mic.aac"
mixed_audio_file="tmp/${input_prefix}_mixed.aac"
output_file="converted/${input_prefix}.mp4"

# For desktop audio
ffmpeg -i "$input_file" -map 0:a:0 -af 'volume=3' -q:a 330 -cutoff 15000 "$desktop_audio_file"
# For minecraft audio
# ffmpeg -i "$input_file" -map 0:a:1 -af 'volume=4.5' "$desktop_audio_file"

ffmpeg -i "$input_file" -map 0:a:3 -c copy "$raw_mic_audio_file"
# Hack no mic audio
# ffmpeg -i "$input_file" -map 0:a:3 -af 'volume=0' "$raw_mic_audio_file"

ffmpeg -i "$desktop_audio_file" -i "$raw_mic_audio_file" -filter_complex amix=inputs=2:duration=first "$mixed_audio_file"

ffmpeg -i "$input_file" -i "$mixed_audio_file" -map 0:v -map 1:a -af 'volume=2' -q:a 330 -cutoff 15000 -c:v copy "$output_file"
