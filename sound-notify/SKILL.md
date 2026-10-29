---
name: sound-notify
description: Play a sound when Claude finishes a task or needs the user's attention, with the user's own MP3/WAV files. Use when the user wants sound or audio notifications, a completion chime, an alert when Claude is waiting for input/permission, or wants to set up, change, add their own, list, test, mute, adjust the volume of, or remove those sounds — e.g. "/sound-notify setup", "/sound-notify set C:\Music\done.mp3", "/sound-notify add ~/Downloads/wow.mp3", "/sound-notify list bass", "/sound-notify volume 40", "/sound-notify mute".
---

# Sound Notify

A skill can't detect "task finished" by itself, so this skill wires Claude Code **hooks** to a small player script:

| Hook event     | Fires when                                    | Default sound (Windows / macOS / Linux)                   |
|----------------|-----------------------------------------------|-----------------------------------------------------------|
| `Stop`         | Claude finishes responding (task complete)    | bundled `sounds/stop.mp3` ("Faaaah", bass boosted) on every OS |
| `Notification` | (opt-in) Claude needs permission or is waiting on input | `Windows Notify System Generic.wav` / `Ping.aiff` / `message.oga` |
| `SubagentStop` | (opt-in) a subagent finishes                  | same as `Stop` unless configured                          |

Only `Stop` is installed by default: the sound plays once, when Claude has finished the whole task and handed control back — not on permission prompts or mid-task questions.

Everything the user can customise lives in one file: `~/.claude/sound-notify.conf`. The scripts re-read it on every event, so edits apply immediately with no restart.

`SKILL_DIR` below = the absolute path of the folder containing this SKILL.md (use forward slashes).

## Commands

Interpret the user's request (or the argument after `/sound-notify`) as one of these. With no argument and no hooks installed yet, run **setup**.

### setup
1. Detect the OS. Hook command per event (`<Event>` = `Stop`, `Notification`, …):
   - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File "SKILL_DIR/scripts/play.ps1" <Event>`
   - macOS/Linux: `bash "SKILL_DIR/scripts/play.sh" <Event>` (Linux needs `ffplay`, `paplay`, `mpg123` or `aplay`; MP3 needs ffplay or mpg123)
2. Read `~/.claude/settings.json` (create `{}` if missing). **Merge — never overwrite** existing hooks. By default install **only `Stop`**, so the sound means "task fully complete" — unless an entry already calls `play.ps1`/`play.sh`:
   ```json
   {
     "hooks": {
       "Stop": [{ "hooks": [{ "type": "command", "command": "<command> Stop", "timeout": 30 }] }]
     }
   }
   ```
   Add `Notification` (permission prompts / waiting for input) or `SubagentStop` (noisy with many subagents) only if the user asks — same shape, event name swapped. Write valid JSON (escape `"` inside the command string).
3. If `~/.claude/sound-notify.conf` doesn't exist, create it from the template below.
4. Run **test**. Tell the user hooks load at session start, so they may need to restart Claude Code (or open `/hooks` once) before they hear it automatically.

### list [filter]
List the files in `SKILL_DIR/sounds/` (247 Indian meme clips from myinstants), filtered by the word if given. `stop.mp3` is the bundled completion default (a copy of `faaaaaaaaaaahhhhhhh-bass-boosted.mp3`).

### add `<file>` [and use it for `<event>`]
The user's own sound joins the library:
1. Confirm the file exists and is audio (`ffprobe` if available, else check the extension against the list under **set**).
2. Copy it into `SKILL_DIR/sounds/` as lowercase-with-hyphens (`My Sound!.mp3` → `my-sound.mp3`). Never overwrite an existing file — ask, or add a `-2` suffix. Never name it `stop.*`/`notification.*` (those are the bundled defaults).
3. If they want it used now, do **set** with the new file for that event (default `Stop`), then **test**.

### default `<file or name>` [for `<event>`]
Change the bundled default that ships with the skill (what everyone hears with no personal setting): replace `SKILL_DIR/sounds/<event>.*` with a copy of the chosen file, named `<event>.<ext>`. For just this user, prefer **set** — it survives skill updates.

### set `<file or name>` [for `<event>`]
- If it isn't a path, treat it as a name: pick the file in `SKILL_DIR/sounds/` whose name matches (e.g. "are baap re" → `are-baap-re-yaad-aya.mp3`); if several match, show them and ask which.
- Expand `~` / env vars, confirm the file exists and the extension is playable (Windows: mp3, wav, wma, m4a, aac; macOS: mp3, wav, aiff, m4a, caf; Linux: anything ffplay plays). If missing, say so — don't write a broken path.
- Offer to copy it into `~/.claude/sounds/` so the setting survives the original being moved or deleted.
- Write `stop_sound=` (default when no event is named), `notification_sound=`, `subagentstop_sound=`, or `sound=` for "all events". Then run **test** for that event.

### volume `<0-100>` · max `<seconds>`
Set `volume=` or `max_seconds=` in the conf. `max_seconds` cuts long tracks off so a full song can't delay Claude (keep it ≤ the hook `timeout`).

### mute / unmute [event]
Whole skill: `enabled=false` / `enabled=true`. One event: `<event>_sound=off` / remove that line.

### test [event]
Run the hook command for the event (default `Stop`) directly and report any `sound-notify:` error from stderr. The scripts always exit 0 so a bad sound file can never break Claude.

### status
Show the conf contents and which hook events in `~/.claude/settings.json` point at this skill.

### uninstall
Remove only the hook entries whose command references `play.ps1`/`play.sh` (drop now-empty event arrays). Ask before deleting `~/.claude/sound-notify.conf`.

## Config template (`~/.claude/sound-notify.conf`)

```ini
# Claude Code sound notifications. Changes apply on the next event.
enabled=true
# 0-100
volume=80
# Longest a sound may play before it is cut off.
max_seconds=5

# Per-event sound files (mp3/wav/...). Blank = OS default, "off" = silent.
# ~ and %ENV% variables are expanded. Quotes optional.
stop_sound=
notification_sound=
# subagentstop_sound=
# Fallback for any event without its own line:
# sound=
```

Lookup order per event: `<event>_sound` → `sound` → bundled `SKILL_DIR/sounds/<event>.*` → OS default.

To change the out-of-the-box sound for everyone who installs the skill, replace `sounds/stop.*` (or add `sounds/notification.*`) — keep one file per event name.
