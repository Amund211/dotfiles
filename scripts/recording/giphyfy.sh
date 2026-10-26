# exit 1

set -eux




filename=$1.mkv
filename=$1


	# -ss 1.5 -to 4.5 \
ffmpeg \
	-i "$filename" \
    -vf "fps=30,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
    -loop 0 "$filename".gif \
    && du -hs "$filename".gif
