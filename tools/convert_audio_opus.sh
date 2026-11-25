#!/bin/bash
# mp3 -> Opus 16 kbps mono (Ogg), trims long silences. Replaces each .mp3 with a .ogg next to it.
f="$1"; o="${f%.mp3}.ogg"
ffmpeg -loglevel error -y -i "$f" -ac 1 -ar 24000 -c:a libopus -b:a 16k -application voip \
  -af "silenceremove=start_periods=1:start_threshold=-50dB:stop_periods=-1:stop_duration=0.6:stop_threshold=-50dB" "$o" && [ -s "$o" ] && rm "$f"
