---
name: ship-cheap
description: Cost-optimized variant of /ship. Same correctness gates, but a LEAN DRIVER that resumes each phase from a handoff summary (not the full transcript), role-based model tiering (Opus only for deep-reasoning seats), and structured/compact agent returns. Autonomy is inherited from the same run-state + Stop-hook ratchet as /ship. Invoked by `/ship-cheap <feature>`. Use when the user wants /ship's rigor at a fraction of the token cost.
---

# /ship-cheap — the frugal self-driving feature pipeline

Same pipeline and same gates as `/ship` (read `~/.claude/skills/ship/SKILL.md` for the canonical
stage→OMC-agent mapping, the readiness hard gate, and the quality gate — they are IDENTICAL here and
must not drift). The ONLY differences are the **execution model**: a lean driver, phase-boundary
handoffs, tiered models, and compact agent returns. Everything about *correctness* (the readiness
hard gate, the quality gate, adversarial review, es/en + a11y charter checks) is preserved — you cut
tokens on the parts that don't buy accuracy, never on the parts that do.

Read the per-repo `.agents/manifest.yml` (surfaces + checklist) and `AGENTS.md` / `.claude/agents/`
for reviewers and golden paths. **Never hardcode a project's personas/commands** — read them at run time.

---

## 1. Autonomy — how it keeps running phase after phase (the core mechanism)

`/ship-cheap` never hands the wheel back between phases. Four pieces guarantee it:

1. **Run-state = durable program counter.** `.omc/state/ship-cheap-<slug>.json` holds `stage`,
   `stages{}`, a decisions/accepted-risks **ledger**, and a per-phase **handoffs** map (artifact paths +
   a compact summary + `nextAction`). Written at the START and updated at EVERY phase boundary. It is the
   single source of truth for "where am I + what's already decided" — and it survives any context reset.

2. **Stop-hook ratchet = the un-skippable enforcer (inherited, zero new infra).** The repo's
   `scripts/quality-gate.sh` runs as the Stop hook and **refuses turn-end** while any
   `.omc/state/ship-*.json` has `active:true && hardGateMet:false` *and this checkout is the run's driver*.
   Because the state file is named `ship-cheap-<slug>.json`, it **matches the existing `ship-*.json` glob** —
   so you cannot end your turn until the final quality gate flips `hardGateMet:true`. That is the mechanical
   guarantee the pipeline marches to completion. (Same escape hatch as /ship: `SKIP_QUALITY_GATE=1` for one
   turn, or set `active:false` to abort.)

3. **Driver loop.** Each iteration: read run-state → pick the next `pending` stage → spawn that phase's
   agent (fresh context, tiered model, **structured return**) → append its handoff to the ledger + mark the
   stage `done` → advance. Repeat until stage 7 flips `hardGateMet`. The driver only pauses for a genuine
   human decision (e.g. the grill's scope question) — never "should I continue?".

4. **Resumability / crash recovery.** State + artifacts live on disk. If the session dies mid-run, a fresh
   session re-invoked on the repo reads run-state, sees `active:true`, and the Stop-hook forces it to resume
   from the recorded `stage` using the handoff ledger — **no transcript needed**. Optionally schedule a
   `ScheduleWakeup` (or a cron via the `schedule` skill) as a heartbeat if nothing else would re-invoke the
   session after a hard crash.

The property that makes this both cheap AND safe: every phase resumes from **(run-state ledger + on-disk
artifacts)**, never from the accumulated transcript. The driver's context therefore stays small, and any
continuation is deterministic.

---

## 2. The lean-driver cost model (why it's cheap)

The expensive thing in a normal /ship run is the **driver accumulating every verbose agent report and
re-reading it every turn** (cache-reads dominate). /ship-cheap removes that at the source:

- **The driver holds almost nothing.** It keeps only: the system prompt, the run-state ledger, and the
  current handoff. It does NOT read big artifacts into its own context — it delegates to a phase-agent that
  reads what it needs from disk and returns a compact result.
- **Every phase is an ephemeral subagent** (`Task`/`Agent`) with a **fresh context** seeded only by the
  prior handoff + the specific artifact paths that phase needs. Heavy reasoning and file-reading happen in
  the agent and die with it.
- **Agents MUST return compact, structured handoffs — not essays.** Give every spawned agent a `schema`
  (or an explicit "return ONLY: `file:line — verdict`, decisions as bullet keys, ≤ N tokens") so 100K-token
  reports never enter the driver's context. This is accuracy-neutral: findings are preserved, prose is not.
- **Checkpoint by REFERENCE, not paraphrase.** The handoff points to complete artifacts
  (`.omc/plans/<slug>.md`, the git diff, `.omc/readiness/<slug>.md`); it never lossily re-summarizes them.
  Losing a detail here is the one real risk — so the handoff carries the *decisions* verbatim and *pointers*
  to everything else.

---

## 3. Model tiering (the biggest cost lever, accuracy-safe)

Reserve the expensive model for the seats where model quality changes the OUTCOME; run the rest cheaper.
Pass `model` explicitly on every `Task`/`Agent` spawn.

| Tier | Model | Phases / agents |
| --- | --- | --- |
| **Reasoning (keep expensive)** | opus | architect (design), planner (`--consensus`), the adversarial **critic + analyst**, security-reviewer, final defect **triage** (the driver's own judgment) |
| **Execution / narrow review** | sonnet | executors (code), code-reviewer, the charter reviewers (narrow `file:line` checks), qa-tester |
| **Locate / mechanical / docs** | haiku | explore / codebase-locator, the writer, translation-parity and generated-doc checks |

Rule of thumb: if the seat is *deciding the design* or *hunting subtle defects*, it stays opus. If it's
*locating*, *executing a spec*, *rubber-stamping a narrow rule*, or *writing prose*, it goes down a tier.
The driver itself: keep its **judgment** sharp (it triages findings) but keep its **context** tiny — the
lean-driver model means even an opus driver is cheap because it isn't re-reading megabytes.

---

## 4. Run-state schema (extended with the ledger)

```json
{
  "slug": "csv-export",
  "feature": "…",
  "branch": "csv-export", "worktree": "…/repo-csv-export", "base": "develop",
  "active": true,
  "startedAt": "2026-07-30T18:00:00Z",
  "stageMarkers": { "research": "2026-07-30T18:00:05Z", "grill": "2026-07-30T18:03:00Z" },
  "stage": "spec",
  "stages": { "research":"done","grill":"done","spec":"in_progress",
              "implement":"pending","review":"pending","test":"pending","gate":"pending" },
  "ledger": {
    "decisions": ["scope=both levels", "sort=unset-last ties A→Z", "UX=drag ↑/↓"],
    "acceptedRisks": ["modal min-width:400px is pre-existing — do NOT re-flag"]
  },
  "handoffs": {
    "research": { "artifacts": [".omc/…"], "summary": "exemplar=…; 5 traps at …", "nextAction": "grill scope" },
    "grill":    { "artifacts": [".omc/specs/deep-interview-csv-export.md"], "summary": "…", "nextAction": "spec" }
  },
  "hardGateMet": false
}
```

- Write it at the **start** (`active:true`, all `pending`, empty ledger, `hardGateMet:false`) in the driver's
  checkout (`<worktree>/.omc/state/ship-cheap-<slug>.json` — see /ship §1 for the driver-checkout rule).
- Update `stages`, `ledger`, and `handoffs` at **every** phase boundary.
- Only stage 7 (quality gate green AND readiness passes) sets `hardGateMet:true`.
- Set `active:false` on completion or abort.

---

## 5. The phases (same as /ship §2, run in the cheap model)

Advance in order; after each phase update run-state and don't proceed until the gate holds. For the exact
OMC agent per phase and the exact gate commands, mirror `~/.claude/skills/ship/SKILL.md` §2 — the deltas:

- **1 Research** — one `explore`/locator on **haiku** → returns a structured map (files + exemplar). Escalate a
  single `architect` on **opus** ONLY if the design is non-obvious; it returns decisions + traps as bullets, not prose.
  Gate: name the exemplar + surfaces. Write handoff.
- **2 Grill** — `deep-interview`, seeded with the manifest's `surfaces` + `checklist`. **Scope is the one place you
  DO ask the human** (`AskUserQuestion`). Record answers verbatim into `ledger.decisions`. Gate: ambiguity below
  threshold AND scope explicitly established.
- **3 Spec + readiness HARD GATE** — `planner --consensus` (opus) + `analyst` (opus) + `critic` (opus) return
  structured findings; the driver synthesizes the plan to `.omc/plans/<slug>.md`. Then render + FULLY answer the
  readiness doc and run `node scripts/check-readiness.js` — **exit 0 required. Do NOT cheapen this gate.**
- **4 Implement** — partition the file list into disjoint sets; one `executor` (**sonnet**) per set, each seeded
  with the plan path (not the transcript). Gate: `make build` / `npm run build` succeeds.
- **5 Review (2× independent + charter lenses)** — `code-reviewer` (sonnet) + `critic` (**opus**, adversarial) on the
  diff; add `security-reviewer` (opus) if auth/permissions/PII touched. Spawn ONLY the charter reviewers whose surface
  is non-N/A per the readiness map (sonnet). Each returns `file:line — verdict` ONLY. The driver (opus judgment)
  triages; fixes loop back to stage 4. **Encode recurring mistakes as ratchets, not prose.**
- **6 Test** — non-browser verification is MANDATORY (unit/integration on **sonnet** qa-tester + `make test`). Browser
  arm is best-effort/env-gated — never brute-force a local env; record `N/A — <reason>` if it won't stand up.
- **7 Quality gate (blocking)** — run the diff-scoped gate (see /ship §2.7 for the `CLAUDE_PROJECT_DIR` +
  `QUALITY_GATE_BASE` overrides in a worktree). Fix every item; re-run until clean. On green → `hardGateMet:true`.

---

## 6. Preconditions, escape hatches, wind-down

Identical to /ship: read the manifest (offer `ship init` if missing); derive `<slug>`; **ASK about isolation**
(worktree vs in-place branch) before touching code; discover commands via `make help`. Escape hatches:
`SKIP_QUALITY_GATE=1`, `OMC_SKIP_HOOKS=…`, `/cancel`. Wind-down: set `active:false`; commit + PR only when the
user asks; **ASK before** worktree/branch cleanup. (See /ship §0, §3, §4.)

---

## 7. What we deliberately DO NOT cheapen (accuracy guardrails)

Cutting cost here would trade a token bill for a production-incident bill — so keep these at full strength:

- The **readiness hard gate** (`check-readiness.js` exit 0) and the **quality gate** (lint + ast-grep + es/en parity
  + migration policy + generated-doc staleness). These are the correctness backbone.
- The **adversarial review seats** (critic + analyst on opus) and the **deep architecture pass** when the design is
  non-trivial — this is where subtle, ship-blocking defects get caught.
- **es/en translation parity** and **a11y** charter checks on any user-facing change.
- The **grill's scope question** — always asked, never inferred. Wrong scope is the most expensive mistake.

Everything else — locating, executing a settled spec, narrow rule-checks, doc writing, and above all the driver
re-reading context — is where the tokens are cut.

---

## 8. Measuring cost (so savings are provable, not assumed)

Use the bundled meter `~/.claude/skills/ship-cheap/ship-cost.mjs` (zero-dep Node). It sums the **main**
transcript + **all subagent** transcripts (`<project>/<sessionId>/subagents/agent-*.jsonl`, across every
project dir a worktree may have forked), **dedupes by message id** (transcripts repeat each message ~3×),
and prices by model. It reproduces ccusage's bucket split (cache-read/write/output) and — unlike ccusage —
gives a **per-phase** and **main-vs-subagents** breakdown.

- Whole run (run it in its OWN session for a clean total): `node ship-cost.mjs`  (defaults to most-recent session)
- A specific session: `node ship-cost.mjs --session <id>`
- Scope one run inside a shared session: `node ship-cost.mjs --session <id> --since <ISO> --until <ISO>`
- Per-phase + auto-bracket from run-state: `node ship-cost.mjs --state .omc/state/ship-cheap-<slug>.json`

**Instrumentation (do this so `--state` works):** the driver stamps ISO timestamps into run-state via
`date -u +%FT%TZ` — `startedAt` at run start, one `stageMarkers.<stage>` at each phase boundary, and
`finishedAt` at wind-down. Also record `sessionId` (basename of the newest `~/.claude/projects/<slug>/*.jsonl`).
The meter then reports cost per phase and brackets the run to `[startedAt, finishedAt]`.

**A/B recipe — measure /ship-cheap vs /ship on the SAME work:**
1. Pick a small feature. From the same base commit, run `/ship <feature>` in a **fresh session** (worktree A).
2. `git reset` a second worktree B to the same base; run `/ship-cheap <feature>` in **another fresh session**.
   (Separate sessions matter — a shared session shares prompt-cache warmth and biases the second run.)
3. `node ship-cost.mjs` in each session → compare **totals AND the token buckets**.
4. Report the ratio. The **cache-read and output token counts** are the rate-independent signal — trust the
   *ratio*, not the absolute dollars (both use the same price table, so any rate offset cancels).
5. LLM runs are noisy; a single pair is directional. For a real number, repeat on 3–5 comparable small
   features and compare medians. Always report *what quality held* (gates passed, defects caught) alongside
   the cost — cheaper is only a win if accuracy held.
