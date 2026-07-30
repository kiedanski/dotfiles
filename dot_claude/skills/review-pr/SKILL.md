---
name: review-pr
description: Understand a GitHub PR by reading it for intent, not bugs. Fetches the PR with gh, checks its head into a throwaway git worktree, analyzes the diff grounded in the actual codebase (including how sibling features were already implemented), and produces a full-screen, vim-navigated terminal walkthrough with a LIVE pane that opens the real source file beside each change. Use when the user wants to review a PR, understand changes, judge whether an approach "makes sense", or get oriented in unfamiliar code. Triggers: "review PR", "review this PR", "help me review", "walk me through PR #".
---

# review-pr

Turn a GitHub PR into a **full-screen, keyboard-driven walkthrough** that helps the
user apply their programming intuition — *"does this make sense? is this the right
approach?"* — rather than hunting for bugs.

You do the expensive analysis once, grounded in the real checked-out code, and bake
it into a `review.json`. A bundled curses TUI renders it as a three-pane,
vim-navigated app whose right pane opens the **actual source file** at each change,
live from the checked-out PR — so the user reads real code in context, not frozen
snippets.

## What the user is optimizing for (learned the hard way)

- **Exploration, not reading.** A wall of pre-written prose fails. The value is
  moving through the change and seeing the real file on the side update as you go.
- **Full keyboard control, vim keys.** No mouse scrolling — ever. Content scrolls
  *inside* the app. `hjkl` navigation is expected.
- **Contextualization over enumeration.** Not "here are the changed lines" but the
  classes/functions involved and where they plug into the existing architecture.
- **Comparison to prior art.** Their #1 need: the diff shows *their* code but not
  *how the codebase already did the same kind of thing*. Every section carries
  `references` to existing siblings, each openable in the live file pane.
- **Judgment prompts, not verdicts.** Questions that poke at consistency, altitude,
  naming, and fit — never "bug" or "fix this".

## Workflow

### 1. Resolve the PR
Arg is a PR number, `owner/repo#number`, or URL. Detect the repo from the URL or
the cwd. If none given, offer `gh pr status`.

```bash
gh pr view <n> --repo <owner/repo> --json number,title,author,url,baseRefName,headRefOid,body,files,additions,deletions
gh pr diff <n> --repo <owner/repo> > /tmp/pr-<n>.diff
```

Read the PR **body** — the author's stated intent is the spine of the gist and map.

### 2. Check the PR head into a throwaway worktree (this powers the live file pane)
The live pane reads real files, so you need the PR head on disk. Do NOT disturb the
user's working tree — use a detached git worktree. Find a local clone (or `gh repo
clone`), then:

```bash
cd <local-clone>
git fetch origin pull/<n>/head
git worktree add --detach /tmp/pr-<n>-tree <PR-head-sha>
```

If the user's checkout is behind the PR (common), say so — the worktree is the
source of truth for both your analysis and the live pane. `repo_root` in the JSON
points at this worktree.

### 3. Ground in the codebase (do not skip — this is the whole point)
Spawn `Explore` / `codebase-pattern-finder` subagents **in parallel** against the
worktree to find how similar things already exist: "how are existing variants
registered and parsed", "what does the direct-text path this mirrors look like",
"where is billing/usage normally set". Their findings become your `references` and
`judgment` questions. A review with no references means you didn't look hard enough.

### 4. Build the review — two layers
**Completeness is non-negotiable: the tool must contain EVERY changed file and
hunk in the PR, even ones you don't write about.** The curated concern-sections are
an annotation layer on top of the full changeset, never a replacement for it.

- **Full file index (`files`):** parse the entire `gh pr diff` into one entry per
  changed file, each with its real hunks (line number from the `@@` header + raw
  diff text). This is the backbone — a user who asks "where's change X?" must be
  able to find it here. Give each file a one-line `blurb` where you can (ideally
  all of them); files covered by a concern section get `blurb: "Covered in §N:
  <title>"` and a `section` id. A file with no blurb still appears — that's fine.
- **Concern `sections`:** group the *interesting* hunks by concern with `summary`,
  `narrative`, `judgment` questions, curated `hunks`, and prior-art `references`.
  Curated hunks/references carry a `path` + `anchor` (a verbatim, distinctive line
  substring) so the TUI opens them precisely. Verify each anchor resolves.

Keep prose tight — the user is a reluctant reader; the real code carries the weight.

### 5. Emit `review.json`
Write to `<repo>/.review-pr/pr-<n>.json`. Mention to the user if `.review-pr/`
isn't gitignored. Schema:

```json
{
  "repo_root": "/tmp/pr-<n>-tree",
  "pr": {"number": 0, "title": "", "url": "", "author": "", "base": "main"},
  "files": [
    {"path": "repo/relative/path.py", "status": "added|modified|deleted",
     "additions": 0, "deletions": 0, "blurb": "one line (or \"Covered in §N: ...\")",
     "section": 3,
     "hunks": [{"line": 394, "diff": "@@ -.. +394,.. @@\n+ real diff text ..."}]}
  ],
  "gist": "2-4 plain sentences: what this PR does and how, at altitude.",
  "map": [
    {"from": "ExistingThing", "action": "extended|added|replaced|routes|injects",
     "to": "what it now does", "note": "one line (optional)"}
  ],
  "sections": [
    {
      "id": 1, "title": "Concern name", "summary": "one line",
      "narrative": "a few sentences: what's going on and why it matters",
      "judgment": ["a question poking at fit/consistency/altitude"],
      "hunks": [
        {"file": "short display label", "range": "human hint",
         "path": "repo/relative/path.py", "anchor": "def some_distinctive_line(",
         "note": "why this matters", "diff": "raw unified diff text (real)"}
      ],
      "references": [
        {"label": "How <sibling> already does this",
         "path": "repo/relative/sibling.py", "anchor": "class Sibling",
         "note": "compare the PR's approach to this prior art",
         "snippet": "real code excerpt"}
      ]
    }
  ],
  "overall_questions": ["cross-cutting judgment prompts"]
}
```

`diff`/`snippet` are real text (from `gh pr diff` and the worktree). `path`+`anchor`
are required on every hunk/reference for the live pane to work; without them a
change still shows its diff but can't open the file.

### 6. Launch
The TUI is interactive and needs a real terminal, so **the user runs it**. Tell them:

```
python3 ~/.claude/skills/review-pr/review_tui.py <repo>/.review-pr/pr-<n>.json
```

(`--repo <path>` overrides `repo_root` if the worktree moved.) Suggest launching it
inline with `!`. Also give a one-paragraph spoken summary of the gist and the 2-3
sharpest open questions in chat, so they get value before opening it.

## Navigation the user gets (three panes: sections | notes | live file)
`j/k` down/up (in the section list, moves selection) · `h/l` move focus across
panes · `Tab` cycle focus · `n/p` (or `] [`) next/previous change, which opens it
in the live file pane · `g/G` top/bottom · `Ctrl-d/Ctrl-u` half-page · `e` open the
current file in `$EDITOR` at the line · `?` help · `q` quit. As the user moves
between sections/changes, the right pane re-opens the real file at the relevant
line. Everything scrolls inside the app — no mouse.

The section list holds the curated concern-sections **and** an "All changed files
(N)" index below them with every file in the PR; selecting a file lists its hunks
and opens the real file. So nothing in the diff is ever missing from the tool.

## Notes
- Not a bug/correctness/security pass. Point at `/code-review` or `/security-review`
  for that.
- Scale to the PR: a 3-file change gets 1-2 sections; a large PR gets more, never
  padded. Missing `references` is the most common failure — always look.
- The worktree lives under /tmp; if it's cleaned up, the live pane degrades to
  showing diffs only. Re-create it with the same `git worktree add` to restore.
