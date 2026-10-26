#!/bin/bash
# Re-encode the raw OBS recordings at the top level of a folder (default ~/recording)
# from NVENC to x264 CRF 16. Subfolders are never touched.
#
# Usage: reencode_replays.sh [--keep] [--ssim] [--limit N] [DIR]
#   --keep     keep each original in DIR/tmp-re-encoded/ instead of deleting it
#   --ssim     also compare every frame with the original (slower)
#   --limit N  stop after N files
#
# Safe to stop with Ctrl-C and run again: files already encoded with x264 are skipped.
# Per file: encode to a work file -> verify -> atomic rename over the original.
# The original is only replaced after the new file passes all checks.
# Logs: DIR/re-encode-logs/, one file per run.

set -u

KEEP=0
SSIM=0
LIMIT=0
while [ $# -gt 0 ]; do
	case "$1" in
	--keep) KEEP=1 ;;
	--ssim) SSIM=1 ;;
	--limit) LIMIT="$2"; shift ;;
	-*) echo "Unknown option: $1" >&2; exit 1 ;;
	*) break ;;
	esac
	shift
done

DIR="$(realpath "${1:-$HOME/recording}")"
WORK="$DIR/.re-encode-work"   # same filesystem as DIR, so renames are atomic
BACKUP="$DIR/tmp-re-encoded"
LOG="$DIR/re-encode-logs/$(date '+%F_%H-%M-%S').log"   # one file per run
MIN_SSIM=0.97
FREE_MARGIN=$((5 * 1024 * 1024 * 1024))

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }
fmt_time() { printf '%dh%02dm' $(($1 / 3600)) $(($1 % 3600 / 60)); }

is_x264() { head -c 8M "$1" | grep -qa 'x264 - core'; }

duration() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null; }

# Everything that must be identical after re-encoding: stream order, codecs (audio is copied),
# packet counts, track titles, languages and default flags.
layout() {
	ffprobe -v error -count_packets \
		-show_entries 'stream=index,codec_type,codec_name,nb_read_packets:stream_disposition=default:stream_tags=title,name,language' \
		-of compact "$1" | sed 's/codec_name=h264//'
}

encode() {
	# Copy each stream's default flag explicitly. Otherwise ffmpeg marks the first
	# audio track as default when the original has no default audio track.
	# OBS mp4 files store track names in a 'name' tag, which ffmpeg only writes back from 'title'.
	local meta=() i=0 d name
	while IFS=, read -r d name; do
		meta+=("-disposition:$i" "$([ "$d" = 1 ] && echo default || echo 0)")
		[ -n "$name" ] && meta+=("-metadata:s:$i" "title=$name")
		i=$((i + 1))
	done < <(ffprobe -v error -show_entries stream_disposition=default:stream_tags=name -of csv=p=0 "$1")
	ffmpeg -nostdin -hide_banner -loglevel error -y -copyts -i "$1" \
		-map 0 -c copy -c:v libx264 -preset medium -crf 16 -profile:v high -fps_mode passthrough \
		"${meta[@]}" "$2" 2>>"$LOG"
}

# Returns 0 if NEW is a faithful re-encode of ORIG
verify() {
	local orig="$1" new="$2"
	is_x264 "$new" || { log "  not x264"; return 1; }
	[ "$(layout "$orig")" = "$(layout "$new")" ] || { log "  stream layout differs"; return 1; }
	awk -v a="$(duration "$orig")" -v b="$(duration "$new")" 'BEGIN { exit !(a - b < 0.1 && b - a < 0.1) }' ||
		{ log "  duration differs"; return 1; }
	if [ "$SSIM" = 1 ]; then
		local ssim
		ssim="$(ffmpeg -nostdin -hide_banner -i "$new" -i "$orig" -lavfi '[0:v][1:v]ssim' -f null - 2>&1 |
			grep -o 'All:[0-9.]*' | cut -d: -f2)"
		log "  ssim ${ssim:-none}"
		awk -v s="${ssim:-0}" -v m="$MIN_SSIM" 'BEGIN { exit !(s >= m) }' || { log "  ssim too low"; return 1; }
	fi
}

# Put NEW in place of ORIG, keeping ORIG's name, mtime and permissions
replace() {
	local orig="$1" new="$2" name
	name="$(basename "$orig")"
	touch --reference="$orig" "$new" && chmod --reference="$orig" "$new" || return 1
	if [ "$KEEP" = 1 ]; then
		# Hard link: the original stays reachable in BACKUP after the rename below.
		# Already linked by an interrupted run is fine; any other file with that name is not.
		if ! [ "$orig" -ef "$BACKUP/$name" ]; then
			ln -- "$orig" "$BACKUP/$name" || return 1
		fi
	fi
	mv -f -- "$new" "$orig"   # atomic: the path always holds a complete file
}

trap 'log "Interrupted"; rm -rf -- "$WORK"; exit 130' INT TERM

mkdir -p "$WORK" "$(dirname "$LOG")" || exit 1
rm -f -- "$WORK"/*   # partial output from an interrupted run
[ "$KEEP" = 1 ] && { mkdir -p "$BACKUP" || exit 1; }

log "Start in $DIR (keep $KEEP, ssim $SSIM, limit $LIMIT)"
shopt -s nullglob
candidates=("$DIR"/*.mkv "$DIR"/*.mp4)
# Measured: about 0.16 s per file, mostly disk reads
log "Scanning ${#candidates[@]} files for x264 and duration (about $(( ${#candidates[@]} * 16 / 100 / 60 + 1 )) min)..."
todo=()
remaining_secs=0
for f in "${candidates[@]}"; do
	[ -f "$f" ] && [ ! -L "$f" ] || continue
	is_x264 "$f" && continue
	todo+=("$f")
	remaining_secs="$(awk -v a="$remaining_secs" -v b="$(duration "$f")" 'BEGIN { print a + b }')"
done
total=${#todo[@]}
log "$total files to re-encode, $(fmt_time "${remaining_secs%.*}") of footage"

done_n=0
ok_n=0
fail_n=0
run_start=$(date +%s)
footage_done=0
for f in "${todo[@]}"; do
	[ "$LIMIT" -gt 0 ] && [ "$done_n" -ge "$LIMIT" ] && break
	[ -f "$f" ] || continue
	name="$(basename "$f")"
	tmp="$WORK/$name"
	size=$(stat -c %s "$f")
	secs="$(duration "$f")"

	free=$(df --output=avail -B1 "$DIR" | tail -1)
	if [ "$free" -lt $((size + FREE_MARGIN)) ]; then
		log "Stopping: only $((free / 1024 / 1024 / 1024)) GB free, $name needs up to $((size / 1024 / 1024 / 1024)) GB + 5 GB margin"
		break
	fi

	log "[$((done_n + 1))/$total] $name ($((size / 1024 / 1024)) MB, ${secs%.*} s)"
	start=$(date +%s)
	if encode "$f" "$tmp" && verify "$f" "$tmp" && replace "$f" "$tmp"; then
		ok_n=$((ok_n + 1))
		log "  OK $((size / 1024 / 1024)) MB -> $(($(stat -c %s "$f") / 1024 / 1024)) MB in $(($(date +%s) - start)) s"
	else
		fail_n=$((fail_n + 1))
		rm -f -- "$tmp"
		log "  FAILED, original kept untouched"
	fi
	done_n=$((done_n + 1))

	# Progress. ETA scales by footage length, since file lengths vary a lot.
	now=$(date +%s)
	elapsed=$((now - run_start))
	footage_done="$(awk -v a="$footage_done" -v b="${secs:-0}" 'BEGIN { print a + b }')"
	remaining_secs="$(awk -v a="$remaining_secs" -v b="${secs:-0}" 'BEGIN { r = a - b; print (r > 0 ? r : 0) }')"
	eta=$(awk -v e="$elapsed" -v d="$footage_done" -v r="$remaining_secs" 'BEGIN { print (d > 0 ? int(e / d * r) : 0) }')
	log "  Done $done_n ($ok_n ok, $fail_n failed), remaining $((total - done_n)), $((elapsed / done_n)) s/file," \
		"ETA $(fmt_time "$eta"), finished at $(date -d "@$((now + eta))" '+%a %H:%M')"
done

rm -rf -- "$WORK"
log "End: $ok_n ok, $fail_n failed, $((total - done_n)) not started"
