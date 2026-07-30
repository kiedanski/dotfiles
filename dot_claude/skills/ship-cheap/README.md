# /ship-cheap

A cost-optimized variant of `/ship`. Same pipeline (research → grill → spec → implement → 2× review →
test → quality gate) and the **same correctness gates**, but a cheaper execution model:

- **Lean driver** — the driver holds only run-state + a handoff ledger; every phase runs as an ephemeral
  subagent with a fresh context seeded from a handoff summary + on-disk artifacts, so the driver never
  accumulates (and re-reads) verbose reports.
- **Phase-boundary handoffs** — resume each phase from a compact summary that *points to* artifacts, never
  a lossy paraphrase.
- **Model tiering** — opus only for the deep-reasoning seats (architecture, adversarial critique, planning,
  triage); sonnet for execution/narrow review; haiku for locating/writing.
- **Structured agent returns** — agents return `file:line — verdict` / decision keys, not essays.

## Autonomy

Inherited from `/ship` with zero new infrastructure: the run-state file is named
`.omc/state/ship-cheap-<slug>.json`, which matches the existing Stop-hook glob (`.omc/state/ship-*.json`
in `scripts/quality-gate.sh`). The hook refuses turn-end while `active:true && hardGateMet:false`, so the
driver is mechanically forced to march phase-by-phase until the final gate is green. Crash-safe: a fresh
session resumes from the run-state ledger + artifacts, no transcript needed.

## What it does NOT cheapen

The readiness hard gate, the quality gate, adversarial review, es/en + a11y charter checks, and the grill's
scope question — the parts where cutting tokens would cost accuracy.

Invoke: `/ship-cheap <feature description>`
