#!/usr/bin/env bash
# Plays the sound configured for a Claude Code hook event (macOS / Linux).
# Usage: play.sh <Event>   e.g. Stop, Notification, SubagentStop
event=$(printf '%s' "${1:-Stop}" | tr '[:upper:]' '[:lower:]')
conf="$HOME/.claude/sound-notify.conf"

get() {
  [ -f "$conf" ] || return
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$conf" | tail -n1 | sed 's/[[:space:]]*$//; s/^"//; s/"$//'
}

[ "$(get enabled)" = false ] && exit 0
sound=$(get "${event}_sound"); [ -z "$sound" ] && sound=$(get sound)
[ "$sound" = off ] && exit 0
sound="${sound/#\~/$HOME}"
# Bundled default: sounds/<event>.* next to scripts/ (e.g. sounds/stop.mp3)
if [ -z "$sound" ]; then
  for f in "$(dirname "$0")/../sounds/$event".*; do [ -f "$f" ] && { sound=$f; break; }; done
fi
volume=$(get volume); case "$volume" in ''|*[!0-9]*) volume=80;; esac; [ "$volume" -gt 100 ] && volume=100
max=$(get max_seconds); case "$max" in ''|*[!0-9.]*) max=5;; esac

if [ "$(uname)" = Darwin ]; then
  [ -z "$sound" ] && { [ "$event" = notification ] && sound=/System/Library/Sounds/Ping.aiff || sound=/System/Library/Sounds/Glass.aiff; }
  cmd=(afplay -v "$(awk "BEGIN{print $volume/100}")")
else
  [ -z "$sound" ] && { [ "$event" = notification ] && sound=/usr/share/sounds/freedesktop/stereo/message.oga || sound=/usr/share/sounds/freedesktop/stereo/complete.oga; }
  if command -v ffplay >/dev/null; then cmd=(ffplay -nodisp -autoexit -loglevel quiet -volume "$volume")
  elif command -v paplay >/dev/null; then cmd=(paplay --volume=$((volume * 65536 / 100)))
  elif command -v mpg123 >/dev/null; then cmd=(mpg123 -q -f $((volume * 32768 / 100)))
  elif command -v aplay >/dev/null; then cmd=(aplay -q)
  else echo "sound-notify: no audio player found (install ffmpeg)" >&2; exit 0
  fi
fi

[ -f "$sound" ] || { echo "sound-notify: file not found: $sound" >&2; exit 0; }

# Stop at end of file or at max_seconds, whichever comes first, so long tracks can't stall Claude.
"${cmd[@]}" "$sound" </dev/null >/dev/null 2>&1 & pid=$!
( sleep "$max"; kill "$pid" 2>/dev/null ) & timer=$!
wait "$pid" 2>/dev/null
kill "$timer" 2>/dev/null
exit 0
