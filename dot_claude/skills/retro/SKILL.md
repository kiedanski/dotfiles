---
name: retro
description: Coding retro / meta-skill. Mines your own Claude Code sessions (transcripts, OMC traces, repowise corrections) + git history for recurring mistakes, and proposes RATCHET-shaped fixes (ast-grep rule / eslint ban / golden-path row / charter reviewer / checklist concern / doc fix) — each with a ready-to-apply diff, presented Apply/Edit/Skip. Global + cross-project. Invoke as `/retro`.
---

# /retro — turn recurring mistakes into ratchets

**The Ratchet Rule:** a recurring mistake is never fixed by adding a sentence to a doc — it's fixed as
a machine-checkable or structural guard. This skill finds ratchet candidates from how you *actually*
work and, on your approval, writes them into the current repo's contract. You approve; you never
hand-author the ratchet.

This skill is **global** (it mines your sessions across every project). Run it **from inside the repo
you want to harden** — the ratchets it writes land in *that* repo's contract, while the mining is
cross-project.

## When
On demand (`/retro`), or scheduled weekly via the `schedule` skill.

## 1. Gather evidence (real data, not vibes)
- **Transcripts:** `~/.claude/projects/*/` JSONL — your session history across projects. Scan for:
  human corrections ("no, use…", "don't…", "actually…", "that's wrong", reverts of your edits),
  repeated re-edits of the same file, repeated failed commands (lint/test re-runs), and tool errors.
- **OMC traces:** `session_search`, `trace_summary`, `trace_timeline` for rework/failure hotspots.
- **repowise CLI (via Bash):** `repowise corrections` (recurring command fumbles mined locally),
  `repowise risk`, `repowise saved`.
- **git:** churn/revert patterns — files repeatedly touched or reverted, fixup/"oops" commits.

Cite **≥3 concrete excerpts** per finding (file/session + quote). No generic advice.

## 2. Cluster into findings
Group the evidence into recurring-mistake findings, ranked by **frequency × blast-radius**. A finding
must be a PATTERN (≥2–3 occurrences), not a one-off.

## 3. Map each finding to a ratchet (the ONLY allowed output shapes)
Every proposal targets exactly one artifact and carries a ready-to-apply diff:

| Mistake shape | Ratchet | Where it's written (current repo) |
|---|---|---|
| Banned/dangerous API or import used | ast-grep rule | `.ast-grep/rules/<name>.yml` (+ `sgconfig.yml`) |
| Forbidden call/syntax (bare `fetch`, raw `require`, …) | ESLint `no-restricted-*` | `eslint.config.js` |
| "Should have read the exemplar first" knowledge gap | golden-path row | `AGENTS.md` |
| A whole review lens keeps being missed | charter reviewer | `.claude/agents/review-<lens>.md` |
| A concern nobody considered (mobile, rollback, tenant…) | checklist concern | `.agents/manifest.yml:checklist` |
| A stale/wrong fact that misled you | doc fix | the specific doc |

If a finding fits none of these, it's **taste, not a convention** — drop it and say so.

## 4. Present interactively (Apply / Edit / Skip)
For each finding, in ranked order, show: the evidence (≥3 cited excerpts), the proposed ratchet, and
the exact diff. Then ask via `AskUserQuestion`: **Apply / Edit / Skip**.
- **Apply** → write the artifact; regenerate anything derived (e.g. `node scripts/gen-makefile.js` if
  the manifest changed, `node scripts/gen-schema-reference.js` if models docs are involved); stage it.
- **Edit** → take the user's tweak, then write.
- **Skip** → record it as considered-and-declined (so the next `/retro` doesn't re-propose it).

## 5. Wind-down
Summarize what was applied. Offer to commit / open a PR (only when the user asks). If not already
scheduled, suggest a weekly `/retro` via the `schedule` skill.

## Guardrails
- **Evidence-first:** never propose a ratchet without citing real occurrences.
- **One ratchet per finding;** the smallest change that catches the whole class.
- **Prove new ast-grep/eslint rules** against a real occurrence AND a clean sample before applying —
  the same false-positive bar the quality gate holds. A noisy rule trains people to ignore the gate.
- Ratchets land in the **current repo's** contract; this skill itself stays global.
