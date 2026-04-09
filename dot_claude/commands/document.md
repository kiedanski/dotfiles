---
description: Document learnings and outcomes from this session
allowed-tools: Read, Edit, Write, Bash(git status:*), Bash(pwd:*), Bash(ls:*), Bash(cat:*)
---

## Environment

- Current directory: !`pwd`
- Git status (for context only): !`git status 2>/dev/null || echo "NOT A GIT REPO"`
- Directory listing: !`ls -la 2>/dev/null`
- Existing CONTEXT.md: !`cat CONTEXT.md 2>/dev/null || echo "NO CONTEXT.md"`
- Existing README.md: !`cat README.md 2>/dev/null | head -80 || echo "NO README.md"`
- Claude README: !`cat ~/.claude/README.md 2>/dev/null || echo "NO ~/.claude/README.md"`

## Your task

You are a session documentation assistant. Your primary source is **the conversation itself** — what was discussed, decided, learned, and built. File changes are secondary context only.

### Step 1 — Extract learnings from the conversation

Read the full conversation history and extract:

- **What problem was being solved** and why it matters
- **What was learned** — discoveries, things that didn't work and why, non-obvious insights
- **Decisions made** — what approach was chosen and the reasoning behind it
- **What was built or configured** — tools, scripts, commands, settings added
- **How to use it** — if something actionable was created, how does one use it?
- **Open questions or follow-ups** — things left unresolved or worth revisiting

### Step 2 — Decide if documentation is needed

**Skip entirely if:**
- The session was only explanatory or exploratory with no lasting outcome
- Everything discussed is already captured in existing docs
- The outcome is too trivial to be useful later (e.g., fixed a one-character typo)

If skipping, say so briefly and stop.

### Step 3 — Determine the documentation target

**Case A — Claude config/customization:**
- Signs: session involved creating or modifying Claude commands, skills, hooks, memory files, MCP servers, Claude settings, or anything under `~/.claude/`
- Target: `~/.claude/README.md` (create if missing)
- This takes priority over Cases B and C if Claude itself was being configured

**Case B — Personal config, dotfiles, system-level scripts:**
- Signs: working in `~`, `~/.config`, `~/.local`, scripts in `~/bin`, shell config, system tooling — but NOT Claude-specific files
- Target: `~/.github/README.md`

**Case C — A specific project:**
- Signs: working inside a project directory with a `.git` repo that isn't home-dir or Claude config
- Target: `CONTEXT.md` at the project root (create if missing)
- Structure:
  ```
  # Context

  ## What This Is
  [brief description — only if new file]

  ## Sessions
  ### YYYY-MM-DD — [short title]
  [content]
  ```

**If ambiguous:** default to Case C if there's a project git repo, otherwise Case B.

**If multiple cases apply** (e.g. Claude config was changed AND a project was worked on): document to both targets, with each entry scoped to what's relevant for that file.

### Step 4 — Draft the entry

Write as if explaining to yourself in 3 months. Be specific and direct.

**Good entries:**
- Capture the *why*, not just the *what*
- Note things that were tried and failed (saves future re-investigation)
- Include usage examples for tools/scripts
- Flag anything surprising or non-obvious

**Avoid:**
- Vague summaries ("did some work on X")
- Reproducing conversation verbatim
- Obvious implementation details readable from the code itself

### Step 5 — Confirm before writing

Show the proposed entry and ask:
> "Does this look right? I'll append it to [target file]. Reply yes to proceed or suggest edits."

Wait for confirmation, then write it.
