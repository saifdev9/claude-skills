# Plays the sound configured for a Claude Code hook event (Windows).
# Usage: play.ps1 <Event>   e.g. Stop, Notification, SubagentStop
param([string]$Event = 'Stop')

$conf = @{}
$confPath = Join-Path $HOME '.claude\sound-notify.conf'
if (Test-Path $confPath) {
  foreach ($line in Get-Content $confPath) {
    if ($line -match '^\s*([^#=\s][^=]*?)\s*=\s*(.*?)\s*$') { $conf[$Matches[1].ToLower()] = $Matches[2].Trim('"') }
  }
}
if ($conf['enabled'] -eq 'false') { exit 0 }

$key = $Event.ToLower()
$defaults = @{ stop = "$env:WINDIR\Media\tada.wav"; notification = "$env:WINDIR\Media\Windows Notify System Generic.wav" }
$sound = $conf["${key}_sound"]
if (-not $sound) { $sound = $conf['sound'] }
# Bundled default: sounds/<event>.* next to scripts/ (e.g. sounds/stop.mp3)
if (-not $sound) { $sound = Get-ChildItem -Path (Join-Path $PSScriptRoot "..\sounds\$key.*") -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
if (-not $sound) { $sound = $defaults[$key] }
if (-not $sound) { $sound = $defaults['stop'] }
if ($sound -eq 'off') { exit 0 }
$sound = [Environment]::ExpandEnvironmentVariables($sound)
if ($sound.StartsWith('~')) { $sound = $HOME + $sound.Substring(1) }
if (-not (Test-Path -LiteralPath $sound -PathType Leaf)) { [Console]::Error.WriteLine("sound-notify: file not found: $sound"); exit 0 }

$volume = 80; if ($conf['volume'] -match '^\d+$') { $volume = [Math]::Min([int]$conf['volume'], 100) }
$max = 5; if ($conf['max_seconds'] -match '^\d+(\.\d+)?$') { $max = [double]$conf['max_seconds'] }

Add-Type -AssemblyName PresentationCore
$p = New-Object System.Windows.Media.MediaPlayer
$p.Volume = $volume / 100
$p.Open([uri](Resolve-Path -LiteralPath $sound).Path)
$p.Play()
# Stop at end of file or at max_seconds, whichever comes first, so long tracks can't stall Claude.
$deadline = (Get-Date).AddSeconds($max)
while ((Get-Date) -lt $deadline -and -not ($p.NaturalDuration.HasTimeSpan -and $p.Position -ge $p.NaturalDuration.TimeSpan)) {
  Start-Sleep -Milliseconds 100
}
$p.Close()
