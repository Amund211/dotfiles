# recording

Scripts that process the OBS recordings and clips in `~/recording`.
They used to live in `~/recording/scripts`. Nothing links that folder
to this one.

The scripts default to `~/recording`, so you can run them from any
directory. `convert.sh` is the exception: run it from `~/recording/clips`.

`obs-backup-2026-10-18/` is a snapshot of the OBS config. It is not
updated automatically.

## Layout of ~/recording

OBS records here (`RecFilePath`). Replay buffer files are `Replay_*`
(mkv or mp4).

| Path | Contents |
| --- | --- |
| `Replay_*`, `YYYY-MM-DD_*.mkv` (top level) | Raw OBS recordings and replays. `process_clips.sh`, `reencode_replays.sh` and `backfill_mix.sh` act on the top level only. |
| `clips/<category>/` | Clips cut by `process_clips.sh`, sorted by category (`pvp`, `clutch`, `bridge`, ...). |
| `clips/bestof/` | Selected best clips. |
| `clips/converted/`, `clips/tmp/` | Output and work files of `convert.sh`. |
| `.processed_clips/` | Replays that `process_clips.sh` is done with. |
| `games/`, `old_games/` | Full games, kept whole. |
| `random/` | Other footage. |
| `audio/`, `rendered/` | Audio work: separate tracks and edited audio. |
| `enctest/`, `test1/` | Encoder tests. |
| `re-encode-logs/` | Logs of `reencode_replays.sh`, one per run. |
| `backfill-mix-logs/` | Logs of `backfill_mix.sh`, one per run. |
| `tmp-backfill-mix/` | Originals kept by `backfill_mix.sh --keep`. |

## Audio tracks

OBS records these tracks: Mix, Desktop Audio, Minecraft Audio,
OBS-denoised, Raw mic. `backfill_mix.sh` adds the Mix track to old
recordings.
