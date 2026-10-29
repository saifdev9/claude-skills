# claude-skills

## [sound-notify](sound-notify/SKILL.md)

Plays a sound when Claude has fully finished a task (optionally also when it needs your input). Default completion sound: "Faaaah" (bass boosted). 247 Indian meme sounds ship in [sound-notify/sounds](sound-notify/sounds).

**Install:** copy `sound-notify/` to `~/.claude/skills/`, then tell Claude `/sound-notify setup`.

**Make it yours** — just ask Claude:

| You say                                      | What happens                                              |
|----------------------------------------------|-----------------------------------------------------------|
| `/sound-notify list bass`                    | Shows the bundled sounds matching "bass"                  |
| `/sound-notify set are baap re`              | Uses a bundled sound by name for task-complete            |
| `/sound-notify set C:\Music\done.mp3`        | Uses any file on your computer                            |
| `/sound-notify add ~/Downloads/wow.mp3`      | Copies your own sound into the library (then optionally sets it) |
| `/sound-notify also notify when you need me` | Opt-in sound for permission prompts / waiting on input    |
| `/sound-notify volume 40` · `mute` · `test`  | Volume 0-100, silence, play it now                        |

**Or by hand:**
- Edit `~/.claude/sound-notify.conf`. Changes apply on the next sound, no restart.
  ```ini
  volume=60
  stop_sound=C:\Users\me\Music\done.mp3   # blank = bundled default, off = silent
  notification_sound=off
  ```
- Add your own sounds by dropping `.mp3`/`.wav` files into `sound-notify/sounds/`.
