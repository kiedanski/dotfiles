# ship

The `/ship <feature>` harness — a self-driving, step-enforced feature pipeline on the OMC engine.
(A skill, not a slash command — commands are deprecated. Invoke as `/ship` or `Skill("ship")`.)

- **Reads:** the target repo's `.agents/manifest.yml` (validation commands, surfaces, checklist) +
  `AGENTS.md`. Calls the repo scripts `render-readiness.js` / `check-readiness.js` and `quality-gate.sh`.
- **Writes:** run-state to `.omc/state/ship-<slug>.json`; readiness to `.omc/readiness/<slug>.md`.
- **Spawns:** OMC agents (explore, architect, deep-interview, planner, executor, code-reviewer,
  critic, security-reviewer, qa-tester, visual-verdict) + the project's `.claude/agents/review-*`
  charter reviewers (only those whose surface is impacted).
- **Enforces:** the repo Stop hook (`scripts/quality-gate.sh`) refuses turn-end while a run is
  `active` and its `hardGateMet` is false — so stages can't be skipped.

See `SKILL.md` for the full stage-by-stage runbook (research → grill → spec → implement → verify
locally (iterate) → review → gate) and the escape hatches.
