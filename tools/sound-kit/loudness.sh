#!/bin/sh
# Measures how loud each sound is, for the mix in
# lib/core/services/sound_service.dart (see "Aturan volume" in
# docs/sound-effects.md). Needs ffmpeg.
#
#   sh tools/sound-kit/loudness.sh                    # every sound
#   sh tools/sound-kit/loudness.sh assets/sounds/quiz # one folder
#   sh tools/sound-kit/loudness.sh assets/sounds/ui/bell.wav
#
# Prints: file, max momentary loudness (LUFS — the number for short
# sounds and loops), integrated loudness (LUFS — the number for music and
# ambience), duration. Short files are padded with silence so the 400 ms
# meter can read them.

set -e
[ $# -eq 0 ] && set -- assets/sounds

find "$@" -type f \( -name '*.wav' -o -name '*.m4a' \) | sort | while read -r f; do
  out=$(ffmpeg -hide_banner -nostats -i "$f" \
    -af "apad=pad_dur=0.5,ebur128" -f null - 2>&1)
  m=$(echo "$out" | grep -o 'M: *-\{0,1\}[0-9.]*' | awk '{print $2}' |
    sort -g | tail -1)
  i=$(echo "$out" | grep -A1 'Integrated loudness' | grep 'I:' |
    awk '{print $2}')
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  printf '%-44s M %6s   I %6s   %6.2fs\n' "$f" "$m" "$i" "$d"
done
