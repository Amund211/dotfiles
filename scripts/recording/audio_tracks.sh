echo "DO NOT RUN THIS SCRIPT!" >&2
exit 1

# Map the app. streams, not re-encoding, but copying instead
ffmpeg -i '2021-02-02_20-56-37.mkv' -codec copy -map 0:v:0 -map 0:a:1 out.mkv

ffmpeg -i 2021-02-02_20-56-37.mkv -c copy -map 0:v:0 -map 0:a:1 out.mkv

# With scale

ffmpeg -i Replay\ 2021-01-31\ 17-48-35.mkv -map 0:v:0 -map 0:a:1 -vf scale=2560x1440 out.mkv


# Good withscale
ffmpeg -i input.mkv -map 0:v:0 -map 0:a:1 -vf scale=2560x1440:flags=lanczos -c:v libx264 -preset slow -crf 18 output.mkv

# Bigboi - with cuts
ffmpeg -i input.mkv -ss 00:00:00 -to 00:01:00 -map 0:v:0 -map 0:a:1 -af 'volume=2.5' -vf 'scale=2560x1440:flags=lanczos, eq=saturation=1.2' -c:v libx264 -preset slow -crf 14 2k_test_sat.mkv

# Bigboi
ffmpeg -i input.mkv -map 0:v:0 -map 0:a:1 -af 'volume=2.5' -vf 'scale=2560x1440:flags=lanczos, eq=saturation=1.2' -c:v libx264 -preset slow -crf 14 output.mkv

# Bigboi - large files
ffmpeg -i input.mkv -map 0:v:0 -map 0:a:1 -af 'volume=2.5' -vf 'scale=2560x1440:flags=lanczos, eq=saturation=1.2' -c:v libx264 -preset fast -crf 10 output.mkv

# Bigboi - large files - preprocessed - with fade
ffmpeg -i input.mkv -map 0 -vf 'scale=2560x1440:flags=lanczos, eq=saturation=1.2, fade=in:0:240, fade=out:17640:240' -c:v libx264 -preset fast -crf 10 output.mkv

# Clip mapper
ffmpeg -i Replay_2021-01-31_17-43-39.mkv -map 0 -c copy -ss 00:33 -to 00:49 clips/output.mkv

# Image inserter
ffmpeg -i input.mp4 -i image.png -filter_complex "[0:v][1:v] overlay=25:25:enable='between(t,0,20)'" -pix_fmt yuv420p -c:a copy output.mp4
# Some explanations:
# 
#     overlay=25:25: The image will be positioned 25px to the right and 25px down, originating from the top left corner (0:0).
#     enable='between(t,0,20)': The overlay image will be shown from 00:00:00 to 00:00:20
