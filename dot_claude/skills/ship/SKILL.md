---
name: ship
description: Self-driving, step-enforced feature pipeline. Invoked by `/ship <feature>`. Composes oh-my-claudecode (OMC) agents to run research → grill → spec → implement → 2× review → test → quality gate, reading the per-repo `.agents/manifest.yml` contract and blocking turn-end until each stage's gate passes. Use whenever the user asks to build/ship a feature in a repo that carries `.agents/manifest.yml`.
---

# /ship — the self-driving feature pipeline

You are the **harness**. When the user runs `/ship <feature description>`, you drive the whole
pipeline yourself, forcing every stage and its gate. You do not hand the wheel back to the user
between stages; you advance stage-by-stage and only stop when the diff is green and the readiness
doc is fully answered — or when a gate genuinely needs a human decision.

OMC is the engine (you spawn its agents). openkanban is the board (leave its hooks alone). The
per-repo `.agents/manifest.yml` is the contract you read; `AGENTS.md` is its prose companion.

## 0. Preconditions

1. **Manifest.** Read `.agents/manifest.yml`. If it is missing, this repo isn't onboarded — offer
   `ship init` (scaffold a minimal manifest + `.claude/` gate from `AGENTS.md`/repo conventions) and
   stop until the user opts in. Everything below assumes the manifest exists.
2. **Slug.** Derive `<slug>` from the feature (kebab-case, `[a-z0-9._-]`). Use it everywhere below.
3. **Isolation — ASK first, then do it.** Before touching code, ask via `AskUserQuestion` whether to
   run this feature in a **fresh git worktree + branch** (recommended — isolates the work and any
   parallel executors from the main checkout) or in-place on a new branch here.
   - Worktree: create and switch to it (`git worktree add ../<repo>-<slug> -b <slug>`, or the
     `EnterWorktree` tool), and run the whole pipeline from there.
   - In-place: if on the default branch, create branch `<slug>` first — never build on the default branch.
   Record the choice + the worktree path (if any) in the run-state file.
4. **Discover commands** via `make help` — always invoke the manifest's real commands, never guess.

## 1. Run-state (this is what makes steps un-skippable)

Persist run-state to **the checkout you're driving the run in** — i.e. `<worktree>/.omc/state/ship-<slug>.json`
when you took a worktree (§0.3), or the repo root's `.omc/state/` for an in-place run — and update it at
every stage boundary. **Rationale:** the Stop-hook gate roots at each session's own `$CLAUDE_PROJECT_DIR`
and can only enforce run-state in *its* checkout, so run-state must live where the run is actually driven.
Keeping it in the driver's checkout means the enforcing gate and the driver coincide — a separate session
on another checkout is never false-blocked, and no state file is shared across instances (which would race).
Do NOT write it to some other/shared checkout.

```json
{
  "slug": "csv-export-vouchers",
  "feature": "add a CSV export button to the vouchers page",
  "branch": "csv-export-vouchers",
  "worktree": "../myapp-csv-export-vouchers",
  "base": "develop",
  "active": true,
  "stage": "spec",
  "stages": { "research":"done","grill":"done","spec":"in_progress",
              "implement":"pending","review":"pending","test":"pending","gate":"pending" },
  "hardGateMet": false
}
```

- Write it at the **start** of the run (`active:true`, all stages `pending`, `hardGateMet:false`).
- **`base`** = the branch you forked from (e.g. `develop`, NOT `main`). Stage 7 passes it as
  `QUALITY_GATE_BASE` so the gate diffs only this feature, not the whole branch divergence.
- The Stop-hook gate (`scripts/quality-gate.sh`) **in that same checkout** reads this file and **refuses
  turn-end while `active:true` and `hardGateMet:false`** — so you can't stop mid-run with an unmet gate.
  (The gate blocks only the run's own driver: a run whose `worktree` names a different checkout is skipped
  there, so unrelated sessions are never false-blocked.)
- Set `"hardGateMet": true` only when **stage 7 (quality gate) is green AND readiness passes**.
- Set `"active": false` on completion, or if the user explicitly aborts (or run `/cancel`).
- Escape hatch for a genuine pause: `SKIP_QUALITY_GATE=1` for one turn (say so out loud).

## 2. The stages (verified OMC mapping — don't re-research)

Advance in order. After each stage, update run-state and **do not proceed until that stage's gate holds.**

### Stage 1 — Research
- `Task(subagent_type="oh-my-claudecode:explore")` to locate the relevant files/surfaces, then
  `Task(subagent_type="oh-my-claudecode:architect")` (read-only, opus) to understand how the area
  works and how sibling features were built.
- For graph/where-is-X, prefer the **`repowise` CLI** via Bash (`repowise search "<q>" --mode symbol|semantic`, `repowise risk`, `repowise impacted-tests`) over blind grep. (CLI, not MCP — MCP availability is fragile.)
- **Gate:** you can name the exemplar to copy (from the `AGENTS.md` golden-path table) and the surfaces touched.

### Stage 2 — Grill (interview)
- `Skill("oh-my-claudecode:deep-interview")` — interactive `AskUserQuestion`, ambiguity-gated
  (default 0.2). **Seed it with BOTH the manifest's `surfaces` (impact map) AND its `checklist`** — read
  those rows from the repo's `.agents/manifest.yml` at run time; do NOT hardcode any project's personas
  or commands into this skill. The interview must be comprehensive on two axes:
  1. **Scope / surfaces FIRST — never assume it.** Before anything else, enumerate the audience rows
     from the manifest's `surfaces` (its `view_*` / persona entries) and ask the human which ones the
     feature applies to. Applying to one surface vs several changes the whole build; don't infer scope
     from the feature title. (The classic miss: assuming a change is end-user-facing only when it also
     needs an internal/admin surface — so ask, using the project's own surface list.)
  2. **Then every concern** in the manifest's `checklist`, **plus** the feature-specific unknowns that
     research surfaced.
- Don't stop at the first plausible interpretation; probe each manifest surface and each concern explicitly.
- Emits `.omc/specs/deep-interview-<slug>.md` — it records the answered **surface scope** + concerns.
- **Gate:** ambiguity below threshold AND the surface scope is **explicitly established** (asked, not inferred).

### Stage 3 — Spec (+ the readiness HARD GATE)
- `Task(subagent_type="oh-my-claudecode:planner")` with `--consensus`, plus `analyst` (gaps),
  `designer` (styling if UI), and `critic` (adversarial review of the plan). Produces `.omc/plans/*.md`.
- Render the readiness doc and require it filled:
  - `node scripts/render-readiness.js <slug>` → `.omc/readiness/<slug>.md` (impact map + concerns).
  - Fill **every** Answer cell (`N/A — <reason>` is valid; a blank is a bug).
  - `node scripts/check-readiness.js .omc/readiness/<slug>.md` — **HARD GATE**: exit 0 required
    (it fails on blank cells, dropped rows, and diff contradictions).
- **Gate:** `check-readiness.js` exits 0.

### Stage 4 — Implement
- Partition the spec's file list into **disjoint** sets and fan out
  `Task(subagent_type="oh-my-claudecode:executor")` (sonnet, writes code) — one executor per set so
  they don't collide. For heavier coordination consider `Skill("oh-my-claudecode:team")`. Use
  `isolation:"worktree"` only if executors would otherwise write the same files.
- **Gate:** the feature is implemented and `npm run build` / `make build` succeeds.

### Stage 5 — Review (2× independent + charter lenses)
- Two **independent** general reviewers on the diff: `Task(subagent_type="oh-my-claudecode:code-reviewer")`
  and `Task(subagent_type="oh-my-claudecode:critic")`. Add `Task(subagent_type="oh-my-claudecode:security-reviewer")`
  whenever auth / permissions / sensitive data is touched.
- **Project charter reviewers** — discover them from the repo's `.claude/agents/` (the `review-*`
  agents). Each declares, in its own description/frontmatter, which surface or concern triggers it;
  spawn ONLY those whose trigger is impacted per the readiness map (its non-N/A rows). **Don't hardcode
  a surface→reviewer mapping here — the project owns it** (read the reviewers' descriptions and
  `.claude/agents/README.md`). Each is read-only and returns `file:line — problem` or `CLEAN`. Spawn the
  selected ones in parallel: `Task(subagent_type="<review-agent-name>", ...)`.
- Triage every finding; fix real ones (loop back to stage 4 if needed). **Encode recurring mistakes
  as ratchets, not prose** (ast-grep rule / eslint ban / golden-path row / charter reviewer / checklist
  concern) — that's what `/retro` later automates.
- **Gate:** no unaddressed high-severity findings; the spawned charter reviewers return `CLEAN` or justified.

### Stage 6 — Test (fork by surface)
**Non-browser verification is mandatory; the browser arm is best-effort and environment-gated — never
brute-force a local environment to run it.**
- **DB / CLI / API / logic (always):** `Task(subagent_type="oh-my-claudecode:qa-tester")` (tmux) + the
  project's unit/integration tests (`make test` / `npm test`). This is the substance of Stage 6.
- **UI / browser (only if a seeded app stands up cleanly):** a working, seeded app is a *precondition*,
  not a task. Look up the project's stack command (manifest `run` / `AGENTS.md`). If one exists and comes
  up in a bounded attempt, drive Chrome via `claude-in-chrome` + `Skill("oh-my-claudecode:visual-verdict")`
  on the impacted surfaces' real entry points — don't infer "works" from a 200.
  - **If there's no declared stack, or standing one up needs manual provisioning (DB auth, missing
    `.env`, no seed script, …): STOP.** Per the browser-automation guidance this is a rabbit hole —
    don't brute-force env setup. Record the UI arm as `N/A — not runnable locally: <reason>` in the run
    notes, and either ask the human to do the visual check or defer browser QA to a provisioned env /
    reviewer. **Never fake a pass.**
- **Gate:** the mandatory non-browser verification passes AND the browser arm is either done or explicitly
  recorded `N/A — <reason>`. Do not hard-block the run on an un-standable local environment.

### Stage 7 — Quality gate (blocking)
- Run the diff-scoped gate against **this feature's** changes; fix every item it frames; re-run until clean.
  Checks: lint + ast-grep + es/en parity + migration policy + generated-doc staleness.
  - In-place on a branch off `main`: `bash scripts/quality-gate.sh </dev/null`.
  - **In a worktree and/or forked from a non-`main` branch, override root + base** so it scopes to just
    this feature's diff (otherwise it either diffs the main checkout — no feature changes — or drags in
    the whole branch divergence):

    ```bash
    CLAUDE_PROJECT_DIR=<worktree-path> QUALITY_GATE_BASE=<base-from-run-state> \
      bash scripts/quality-gate.sh </dev/null
    ```

    `CLAUDE_PROJECT_DIR`→the worktree so the gate diffs the worktree; `QUALITY_GATE_BASE`=the run-state
    `base` (the branch you forked from, e.g. `develop`).
- Optional advisory: `Skill("oh-my-claudecode:merge-readiness")`.
- On green: set `hardGateMet:true` in the run-state file (in the driver's checkout). This is the only stage that flips it.

## 3. Wind-down
- Set `active:false` in the run-state file.
- Advisory `merge-readiness`; let openkanban's hook update board status (don't set it by hand).
- Commit (respect the repo's commit convention) and open the PR only when the user asks.
- **Cleanup — ASK first, then do it.** After the PR/commit, ask via `AskUserQuestion` whether to clean
  up the isolation: `git worktree remove <path>` and/or delete the local `<slug>` branch. Do it ONLY
  on an explicit yes, and NEVER remove a worktree or branch that still holds uncommitted/unmerged work
  without confirming that's intended.

## 4. Escape hatches (say which one you're using)
- `SKIP_QUALITY_GATE=1 <cmd>` — bypass the Stop-hook gate for one turn.
- `OMC_SKIP_HOOKS="persistent-mode,workflow-drift-guard"` / `DISABLE_OMC=1` — if OMC hooks fight the gate.
- `/cancel` — cancel an active OMC mode; also set `active:false` in the run-state file.

## 5. OMC gaps this harness supplies
The browser test arm (chrome MCP + `visual-verdict`), the **second independent reviewer** wiring, the
project **charter reviewers**, and the **blocking** completion gate (OMC's `merge-readiness` is advisory
only, not Stop-wired). Everything else is stock OMC — compose it, don't reinvent it.
