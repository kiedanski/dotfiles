---
allowedTools:
  - Bash(uv run *process_video.py*)
  - Bash(uv run *extract_frames.py*)
  - Bash(ffmpeg*)
  - Bash(ffprobe*)
  - Bash(mkdir*)
  - Bash(ls /tmp/video-analyst*)
  - Bash(cat /tmp/video-analyst*)
  - Read(/tmp/video-analyst*/*)
  - Read(/tmp/video-analyses/*)
  - Read(~/.claude/skills/*)
---

# Skill: Video Analyst

Use this skill when the user invokes `/video-analyst` or asks to analyze a screen recording.

## Behavior

When invoked, spawn a **subagent** using the Agent tool (general-purpose) to handle all
processing and analysis. Do not analyze the video in the main conversation — delegate entirely
to the subagent to keep the main context clean.

## Subagent instructions (pass verbatim)

Tell the subagent:

```
You are analyzing a screen recording. The scripts are at ~/.claude/skills/.
All scripts are run with `uv run <script>` — no install needed.

VIDEO_PATH: <the path the user provided>
OUTPUT_DIR: /tmp/video-analyst-<random 6 chars>/
SUMMARY_PATH: /tmp/video-analyses/<YYYY-MM-DD>/<video-basename-no-ext>.md
  e.g. /tmp/video-analyses/2026-03-11/simplescreenrecorder-2026-03-10.md
  Create the directory if it doesn't exist.

## Rules — read before starting

- Use ONLY the tools listed below. Do not use any other Bash commands.
- Do NOT read script source files to understand them — trust this spec.
- Do NOT use piped commands (|), grep, sed, python3 inline, or any shell tricks.
- Do NOT improvise if a step fails — report the exact error and stop.
- Do NOT use ls to discover files — use the paths from transcript.json directly.
- Allowed tools:
    Bash: uv run *process_video.py*, uv run *extract_frames.py*, mkdir
    Read: /tmp/video-analyst*/* and /tmp/video-analyses/* (for files only)
    Write: for the summary markdown

## Steps

Step 1 — Create dirs and process the video:
  Run:
    mkdir -p <OUTPUT_DIR> /tmp/video-analyses/<YYYY-MM-DD>
  Then:
    uv run ~/.claude/skills/process_video.py \
      --video <VIDEO_PATH> \
      --output <OUTPUT_DIR> \
      --interval 5 \
      --model base

  If this fails, report the error output verbatim and stop — do not attempt to
  re-implement transcription or frame extraction yourself.

  On success it writes <OUTPUT_DIR>/transcript.json containing:
  - transcript: [{start, end, text}, …]
  - thumbnails: [{timestamp, path}, …] one every 5s
  - scene_changes: [t1, t2, …] timestamps of significant visual changes

Step 2 — Build a combined timeline:
  Read <OUTPUT_DIR>/transcript.json using the Read tool.
  Read each thumbnail image listed in the thumbnails array using the Read tool
  (use the path field directly — do not ls the directory).
  For each thumbnail at time T, find the overlapping or nearest transcript segment.
  Build a timeline of (timestamp, what_is_said, what_is_visible).

Step 3 — Select frames to examine at full resolution:
  Use scene_changes and transcript together to pick timestamps:
  - For short segments (<10s): one frame at the scene change within it,
    or the segment midpoint if no scene change falls inside
  - For long segments (≥10s): one frame per scene change within the segment
    plus one at the start; cap at 3 frames per segment
  - Always include t=1s and t=<duration-1>s
  - Hard cap: 20 frames total, prioritising moments where speech + visual change coincide

  Run:
    uv run ~/.claude/skills/extract_frames.py \
      --video <VIDEO_PATH> \
      --output <OUTPUT_DIR>/frames/ \
      --timestamps <t1> <t2> <t3> ...

  Read each frame listed in the JSON output using the Read tool.

Step 4 — Write the analysis to SUMMARY_PATH:
  Use the Write tool to save a markdown file at SUMMARY_PATH containing:
  - Video filename and date analyzed
  - Full transcript
  - What the person is doing (overall narrative)
  - What they are explaining or demonstrating
  - Key technical details visible in the selected frames
  - Any errors, warnings, or issues shown
  - Action items or takeaways
  - A timestamped outline of the video's structure

Step 5 — Return the summary path:
  Your final output must include the line:
    Summary written to: <SUMMARY_PATH>
```

## Invocation

Accept the video path as the argument: `/video-analyst /path/to/recording.mp4`

If no path is given, ask the user for it before launching the subagent.

Optional flags the user can pass (forward to the scripts):
- `--interval N` — thumbnail every N seconds (default 5)
- `--model tiny|base|small|medium` — Whisper model (default base; use small/medium for better accuracy)
