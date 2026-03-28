# Plan: PM Framework Document

## Context

Diego manages multiple concurrent enterprise engagements at LlamaIndex. The current system tracks milestones as toggle headings inside Notion project pages — this works for slide generation but conflates milestones with tasks, has no deliverables layer (KPMG has 3 distinct workstreams with no way to represent that), and milestones can't be queried or scored across engagements.

Goal: Write a PM framework document in the repo that defines the operating model, data hierarchy, Notion schema (ready to build), and future health/automation model — grounded in real data from CVL Agentic and KPMG.

## Decisions made

- **Hierarchy**: Engagement → Deliverable(s) → Milestones (no tasks — FDEs own those separately)
- **Milestones are maturity stages**, not tasks or components
- **Metrics**: targets at Deliverable level, snapshots at Milestone level
- **Reporting**: per-milestone (grouped by deliverable on slides)
- **Doc location**: in the repo (version controlled, Claude Code context)
- **Schema scope**: full Notion DB fields, relations, and status values included in the doc
- **Notion DBs**: separate standalone databases (Deliverables DB, Milestones DB) with relations to FDE Projects DB — queryable across all engagements
- **Health scoring & detection loops**: defined conceptually in the doc, built later

## What to write

**File**: `/home/rbk/workspace/fde-org/pm-framework.md`

### Document structure

1. **Purpose & scope** — what this doc is, who it's for

2. **Data hierarchy**
   - Engagement: time-boxed delivery contract. Maps to FDE Projects DB record.
   - Deliverable: distinct workstream within an engagement. 1..N per engagement. Carries target metrics.
   - Milestone: maturity stage of a deliverable. Progressive gates, not tasks. Carries metric snapshots.
   - Tasks: out of scope — FDE-owned in FDE Issue Tracking DB.

3. **Milestone vs task distinction** — clear table showing ownership, purpose, tracking location, reporting

4. **Metrics model**
   - Deliverable-level targets (accuracy ≥ 40%, cost ≤ $1.18)
   - Milestone-level snapshots (at M2: accuracy = 41.1%)
   - Trajectory tracking across milestones

5. **Status values**
   - Engagement: Active / Paused / Completed (already in FDE Projects DB)
   - Deliverable: Not started / In progress / Done / At risk
   - Milestone: Not started / In progress / In review / Done / Blocked / At risk / Postponed

6. **Notion schema** — exact DB definitions:
   - **FDE Projects DB** (existing, minor additions needed): add health score field
   - **Deliverables DB** (new): name, description, engagement (relation → FDE Projects), status, target metrics
   - **Milestones DB** (new): name, deliverable (relation → Deliverables), status, week/date, acceptance criteria, metric snapshots (Name/Unit/Target/Value), results, blockers
   - **FDE Issue Tracking DB** (existing, no changes): stays FDE-owned

7. **Concrete examples**
   - CVL Agentic fully decomposed: 1 engagement → 1 deliverable → 4 milestones
   - KPMG fully decomposed: 1 engagement → 3 deliverables → milestones per deliverable

8. **Weekly reporting** — milestones are the reporting unit, deliverables group them on slides

9. **Health scoring model** (defined for future implementation)
   - 5 dimensions scored 1–5: milestone health, customer health, team velocity, technical quality, renewal signal
   - Escalation thresholds: < 3.0 immediate, 3.0–3.5 flag, ≥ 4.0 trigger renewal

10. **Detection loops** (defined for future implementation)
    - Milestone slip detection (daily)
    - Meeting prep/follow-up
    - Slack commitment tracking
    - Approval workflow via Telegram/Slack

11. **Principles**
    - Zero engineer reporting — infer from artifacts
    - Draft-first external comms — nothing sends without approval
    - Minimal meetings — kickoff, milestone demos, retro only

## Source material

- Diego's PM framework context doc: `~/Downloads/pm-framework-context.md`
- CVL Agentic project file: `~/notes/work/llamaindex/bp-cvl-agentic.md`
- KPMG project file: `~/notes/work/llamaindex/kpmg-content-harvesting.md`
- Current FDE Projects DB: `https://www.notion.so/329db4b7d41a803bac26e0a8a039bd1a`
- Current FDE Issue Tracking DB: `https://www.notion.so/311db4b7d41a8044aaf5d71dc37fd4dd`
- Current Notion page structure: `.claude/skills/milestones/SKILL.md`

## Impact on existing tooling (future work, not part of this step)

Once the schema is built:
- `notion_reader.py` → query Milestones DB + Deliverables DB instead of parsing toggle headings
- `milestones.py` → generate slides from DB records
- `validate_milestones.py` → validate DB records instead of page format
- Weekly update skill → update DB records via MCP
- Milestones skill → document DB schema

## Verification

- The doc should be self-contained: someone unfamiliar with the project can read it and understand the full model
- CVL Agentic and KPMG examples should be fully decomposed with no ambiguity about what's a deliverable vs milestone
- Notion schema should be concrete enough to create the databases directly from the doc
- Health scoring section should be clearly marked as "future — not yet implemented"
