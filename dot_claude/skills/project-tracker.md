# Skill: Project Tracker

Use this skill when the user invokes `/project-tracker` or asks to update, review,
or report on a PROJECT.txt file.

## File Format Reference

Project files use `=== SECTION_NAME ===` delimiters. Sections in order:

```
=== META ===          # Project identity, contacts, links, overall status
=== MILESTONES ===    # Dated deliverables with status tags
=== ISSUES ===        # Active blockers, risks, waiting-fors, decisions needed
=== WEEKLY_GOALS ===  # Current + recent week task lists
=== CONTEXT ===       # Background, stakeholders, decisions log, notes
```

### Status Tags

**MILESTONES:** `[DONE]` `[ON_TRACK]` `[AT_RISK]` `[BLOCKED]` `[PENDING]`

**ISSUES:** `[OPEN]` `[RESOLVED]` `[WAITING]`
Issue types: `[BLOCKER]` `[RISK]` `[DECISION]` `[DEPENDENCY]` `[ADMIN]`
Priority: `HIGH` / `MED` / `LOW`

**WEEKLY_GOALS:** `[ ]` pending · `[x]` done · `[>]` moved to next week · `[-]` dropped

### Line Formats

```
# MILESTONES
[STATUS]    Target: YYYY-MM-DD | Milestone name | Notes

# ISSUES
[STATUS][TYPE] PRIORITY | Description | Owner | Since YYYY-MM-DD | Notes

# WEEKLY_GOALS week header
## Week of YYYY-MM-DD

# CONTEXT — Key Decisions
YYYY-MM-DD | Decision made | Rationale | Decided by
```

---

## CLI Tool

`ptrack` is available at `~/.local/bin/ptrack`. Commands:
- `ptrack status` — META + MILESTONES + ISSUES
- `ptrack show SECTION` — single section
- `ptrack week` — WEEKLY_GOALS
- `ptrack sections` — list all sections

Read the project file with `ptrack show` or by reading PROJECT.txt directly.

---

## Proposal Format (Workflows A and B)

ALL proposed changes must use this format before touching the file.
Present ALL changes first, wait for responses, then apply only the accepted ones.

```
PROPOSED CHANGES — [Project Name]
Date: YYYY-MM-DD
Source: [meeting notes | voice memo | documents]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CHANGE 1 of N
Section:  MILESTONES
Action:   ADD | MODIFY | REMOVE
Current:  (paste existing line, or "—" if adding)
Proposed: (the new line exactly as it would appear in the file)
Reason:   One sentence explaining why.

Accept? (y/n)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CHANGE 2 of N
...
```

Rules:
- Never edit the file until the human has responded to the full proposal.
- Accept `y`, `yes`, `n`, `no` (case-insensitive) as valid responses.
- After responses: summarize which changes were accepted, then apply them all at once.
- If the human says "all yes" or "accept all", apply everything.
- Do not invent information not present in the source material.
- Be conservative: when unsure, flag as a question instead of proposing a change.

---

## Workflow A — Update from Documents

**Trigger:** User pastes meeting notes, emails, chat logs, or any external text.

**Steps:**
1. Read the current PROJECT.txt with `ptrack show` or Read tool.
2. Parse the pasted material carefully.
3. Extract only information relevant to the project:
   - New or changed milestone status
   - New blockers, risks, or resolved issues
   - Decisions made
   - New contacts or stakeholders
   - Changes to timeline or scope
   - Action items with owners
4. Build the full proposal list using the Proposal Format above.
5. Present the proposal. Wait for yes/no on each change.
6. Apply accepted changes.
7. Update `Last Updated:` in META to today's date.

**Do not** summarize or rephrase the source material beyond what fits in the file format.
**Do not** add speculation — only concrete facts from the source.

---

## Workflow B — Update from Voice / Brain Dump

**Trigger:** User says "I'll talk for a bit about the project" or pastes a transcript
of spoken notes.

**Steps:**
1. Read the current PROJECT.txt.
2. Listen to / read the voice input fully before proposing anything.
3. Identify relevant updates, sorted by section.
4. Build the proposal list using the Proposal Format.
   - Keep proposed lines concise — this is a tracker, not a document.
   - If something belongs in CONTEXT > Notes, quote the key idea briefly.
5. Present the proposal. Wait for yes/no responses.
6. Apply accepted changes.
7. Update `Last Updated:` in META.

**Tip:** Voice input often contains repeated thoughts or uncertainty. Pick the clearest
version of each point. If the user contradicts themselves, flag it as a question.

---

## Workflow C — Reflective Review

**Trigger:** User asks for a review, health check, or "what should we be thinking about".

**Steps:**
1. Read the entire PROJECT.txt.
2. Analyze for:
   - **Staleness:** Last Updated date, issues open >2 weeks, milestones without recent notes
   - **Inconsistencies:** Milestone marked ON_TRACK but a BLOCKER issue is open; dates in the past with no status change
   - **Missing information:** Empty fields in META, milestones without target dates, issues without owners
   - **Risks:** AT_RISK milestones, HIGH priority issues, upcoming deadlines in next 2 weeks
   - **Momentum:** WEEKLY_GOALS completion rate over recent weeks
3. Output a structured review:

```
PROJECT REVIEW — [Project Name]
Date: YYYY-MM-DD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HEALTH: GREEN | YELLOW | RED
One-line summary of current status.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
QUESTIONS (need human input)
  Q1. ...
  Q2. ...

FLAGS (things that look off)
  ! ...
  ! ...

SUGGESTIONS
  → ...
  → ...

UPCOMING DEADLINES (next 14 days)
  YYYY-MM-DD | Milestone/Goal name

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

4. After review, ask: "Would you like to update anything based on this review?"
   If yes, switch to Workflow B mode.

---

## Workflow D — Weekly Report

**Trigger:** User asks to prepare the weekly report or status update.

**Steps:**
1. Read the entire PROJECT.txt.
2. Identify: what was done this week, what is planned next, blockers, overall status.
3. Ask the user: "What format do you want? Options:
   a) Markdown outline (paste into email / doc)
   b) Marp slides (render with `marp report.md`)
   c) Plain text bullets"

   *(Format decision is still pending — update this skill when decided.)*

4. Draft the report using this structure regardless of format:

```
WEEKLY STATUS — [Project Name]
Week of: YYYY-MM-DD
Prepared: YYYY-MM-DD

OVERALL STATUS: GREEN | YELLOW | RED

THIS WEEK
  - [what was accomplished]

NEXT WEEK
  - [planned goals]

BLOCKERS / RISKS
  - [any open HIGH issues or AT_RISK milestones]

UPCOMING MILESTONES
  - YYYY-MM-DD | Milestone name | Status

KEY DECISIONS THIS WEEK
  - [from CONTEXT > Key Decisions if dated this week]
```

5. Show the draft. Ask: "Any changes before I save this?"
6. Save as `REPORT-YYYY-MM-DD.[md|txt]` in the same directory as PROJECT.txt.
7. Do NOT auto-update PROJECT.txt from the report — only update it via Workflows A/B.

---

## General Rules

- Always read the current file before proposing changes.
- Never rewrite large blocks of the file at once — surgical edits only.
- Preserve existing formatting conventions (alignment, tag style).
- When adding a new ISSUE, put it at the top of the section (most recent first).
- When adding a new week to WEEKLY_GOALS, add it above the previous week.
- Dates are always ISO format: YYYY-MM-DD.
- If you are unsure which section something belongs to, ask rather than guessing.
