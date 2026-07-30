# retro

The `/retro` meta-skill — mines how you actually work and proposes **ratchet-shaped** fixes.
(A skill, not a command. Invoke as `/retro` or `Skill("retro")`.) Global + cross-project.

- **Reads:** `~/.claude/projects/*/` JSONL transcripts, OMC `session_search`/`trace_*`, the `repowise`
  CLI (`corrections`, `risk`, `saved`), and git churn/revert history.
- **Proposes:** each recurring mistake as one of — ast-grep rule / ESLint `no-restricted-*` / `AGENTS.md`
  golden-path row / `.claude/agents/review-*` charter reviewer / `.agents/manifest.yml` checklist concern
  / doc fix — with a ready-to-apply diff.
- **Interactive:** Apply / Edit / Skip per finding via `AskUserQuestion`; writes on approval. You never
  hand-author the ratchet.
- **Where it writes:** the ratchets land in the **current repo's** contract; run `/retro` from inside
  the repo you want to harden. The skill itself is global.

Closes the loop with the `ship` skill: `/ship`'s review stage catches mistakes; `/retro` turns the
recurring ones into guards so they can't recur. See `SKILL.md` for the full runbook.
