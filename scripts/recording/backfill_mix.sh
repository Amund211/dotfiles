#!/bin/bash
# Add a "Mix" audio track (Desktop Audio + Raw mic) as the first, default audio track
# to the OBS replays (Replay_*) at the top level of a folder (default ~/recording).
# This gives old recordings the same layout that OBS now records:
#   Mix, Desktop Audio, Minecraft Audio, OBS-denoised, Raw mic
# Subfolders are never touched. Video and the original audio tracks are copied, not re-encoded.
#
# Usage: backfill_mix.sh [--keep] [--limit N] [DIR]
#   --keep     keep each original in DIR/tmp-backfill-mix/ instead of deleting it
#   --limit N  stop after N files
#
# Safe to stop with Ctrl-C and run again: files that already have a Mix track are skipped.
# Per file: write a work file -> verify -> atomic rename over the original.
# The original is only replaced after the new file passes all checks.
# Do not run at the same time as reencode_replays.sh: both rewrite the same files.
# Logs: DIR/backfill-mix-logs/, one file per run.

set -u

KEEP=0
LIMIT=0
while [ $# -gt 0 ]; do
	case "$1" in
	--keep) KEEP=1 ;;
	--limit) LIMIT="$2"; shift ;;
	-*) echo "Unknown option: $1" >&2; exit 1 ;;
	*) break ;;
	esac
	shift
done

DIR="$(realpath "${1:-$HOME/recording}")"
WORK="$DIR/.backfill-mix-work"   # same filesystem as DIR, so renames are atomic
BACKUP="$DIR/tmp-backfill-mix"
LOG="$DIR/backfill-mix-logs/$(date '+%F_%H-%M-%S').log"   # one file per run
OLD_LAYOUT='Desktop Audio|Minecraft Audio|OBS-denoised|Raw mic'
MIC_CUT_DB=9.5
FREE_MARGIN=$((5 * 1024 * 1024 * 1024))

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }
fmt_time() { printf '%dh%02dm' $(($1 / 3600)) $(($1 % 3600 / 60)); }

duration() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null; }

# Audio track names joined by '|'. OBS mkv uses a 'title' tag, OBS mp4 a 'name' tag.
audio_names() {
	ffprobe -v error -select_streams a -show_entries stream_tags=title,name -of csv=p=0 "$1" |
		paste -sd '|'
}

# One line per stream with everything that must survive the copy. Reads the whole file once.
streams() {
	ffprobe -v error -count_packets \
		-show_entries 'stream=codec_type,codec_name,channels,nb_read_packets,start_time:stream_tags=title,name' \
		-of compact "$1" | sed 's/|tag:\(title\|name\)=/|tag=/'
}

mix() {
	# Explicit titles and default flags: the mix is the only default audio track.
	# ffmpeg writes the mp4 'name' tag only from 'title'.
	local meta=() i=1 name
	while IFS= read -r name; do
		meta+=("-metadata:s:a:$i" "title=$name" "-disposition:a:$i" 0)
		i=$((i + 1))
	done < <(audio_names "$1" | tr '|' '\n')
	# Mic at -9.5 dB: the balance convert.sh used, and about what the old 150 % mic volume added.
	# No limiter: at this level the sum stays below 0 dBFS. s16 clips like the OBS output does.
	# 256k instead of OBS's 160k, since this encodes already lossy audio a second time.
	ffmpeg -nostdin -hide_banner -loglevel error -y -copyts -i "$1" \
		-filter_complex "[0:a:3]volume=-${MIC_CUT_DB}dB[mic];[0:a:0][mic]amix=inputs=2:normalize=0,aformat=sample_fmts=s16[mix]" \
		-map 0:v -map '[mix]' -map 0:a -c copy -c:a:0 aac -b:a:0 256k \
		-metadata:s:a:0 title=Mix -disposition:a:0 default "${meta[@]}" "$2" 2>>"$LOG"
}

# Returns 0 if NEW is ORIG with a Mix track added in front of the original audio tracks
verify() {
	local orig="$1" new="$2" new_streams
	[ "$(audio_names "$new")" = "Mix|$OLD_LAYOUT" ] || { log "  track names differ"; return 1; }
	# Stream 1 is the mix; without it, the new file must have exactly the original streams
	new_streams="$(streams "$new")"
	[ "$(streams "$orig")" = "$(sed 2d <<<"$new_streams")" ] || { log "  copied streams differ"; return 1; }
	[ "$(ffprobe -v error -select_streams a -show_entries stream_disposition=default -of csv=p=0 "$new" | paste -sd ,)" = 1,0,0,0,0 ] ||
		{ log "  default flags wrong"; return 1; }
	awk -v a="$(duration "$orig")" -v b="$(duration "$new")" 'BEGIN { exit !(a - b < 0.1 && b - a < 0.1) }' ||
		{ log "  duration differs"; return 1; }
	# The mix must start with Desktop Audio and have about the same number of packets
	sed -n '2p;3p' <<<"$new_streams" | awk -F'|' '
		{ for (i = 1; i <= NF; i++) { split($i, kv, "="); v[NR, kv[1]] = kv[2] } }
		END { ds = v[1, "start_time"] - v[2, "start_time"]; dp = v[1, "nb_read_packets"] - v[2, "nb_read_packets"]
			exit !(ds < 0.05 && ds > -0.05 && dp <= 2 && dp >= -2) }' ||
		{ log "  mix not aligned with Desktop Audio"; return 1; }
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

log "Start in $DIR (keep $KEEP, limit $LIMIT)"
shopt -s nullglob
candidates=("$DIR"/Replay_*.mkv "$DIR"/Replay_*.mp4)
log "Scanning ${#candidates[@]} files for the old track layout..."
todo=()
remaining_secs=0
for f in "${candidates[@]}"; do
	[ -f "$f" ] && [ ! -L "$f" ] || continue
	names="$(audio_names "$f")"
	case "$names" in
	"Mix|$OLD_LAYOUT") continue ;;
	"$OLD_LAYOUT") ;;
	*) log "Skipping $(basename "$f"): unknown track layout '$names'"; continue ;;
	esac
	todo+=("$f")
	remaining_secs="$(awk -v a="$remaining_secs" -v b="$(duration "$f")" 'BEGIN { print a + b }')"
done
total=${#todo[@]}
log "$total files to backfill, $(fmt_time "${remaining_secs%.*}") of footage"

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
	if mix "$f" "$tmp" && verify "$f" "$tmp" && replace "$f" "$tmp"; then
		ok_n=$((ok_n + 1))
		log "  OK in $(($(date +%s) - start)) s"
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
