# Claude Config

Personal Claude Code setup — commands, skills, and customizations.

## Sessions

### 2026-03-10 — /document command

Created `~/.claude/commands/document.md`, a slash command that documents session learnings.

**Usage:** `/document` at the end of any session.

**How it works:** Reads the conversation to extract learnings, decisions, and what was built — then routes to the right file:
- Claude config changes → `~/.claude/README.md`
- Personal dotfiles/scripts → `~/.github/README.md`
- Project work → `CONTEXT.md` in the project root

Always proposes the entry before writing. Skips if nothing meaningful happened.

**Location:** `~/.claude/commands/document.md`

### 2026-03-11 — /video-analyst skill

Created a `/video-analyst` command to analyze screen recordings with audio — record yourself doing/explaining something, and Claude extracts a transcript + understands the video.

**Usage:** `/video-analyst /path/to/recording.mp4`

Optional flags: `--interval N` (thumbnail every N seconds, default 5), `--model tiny|base|small|medium` (Whisper accuracy, default base).

**How it works:**
1. Command spawns a **subagent** (isolated context — keeps main conversation clean)
2. Subagent runs `process_video.py` → ffmpeg extracts audio, faster-whisper transcribes it, ffmpeg extracts 480px thumbnails every N seconds
3. Subagent reads transcript + all thumbnails, **decides** which timestamps are interesting
4. Subagent runs `extract_frames.py` with chosen timestamps → full-res frames at those moments
5. Subagent writes analysis to `/tmp/video-analyses/YYYY-MM-DD/<video-basename>.md` and returns the path

**Key design decision:** Claude reasons about which frames to zoom into (from small thumbnails + transcript) rather than blindly sending all frames at full res. Avoids context bloat.

**Files:**
```
~/.claude/commands/video-analyst.md  ← command definition (allowedTools scoped here)
~/.claude/skills/process_video.py    ← whisper + thumbnails (uv inline deps)
~/.claude/skills/extract_frames.py   ← full-res frame extraction (uv inline deps)
```

Dependencies managed by `uv run` inline script metadata — no global installs needed. `faster-whisper` downloads on first use (~300MB cached).
