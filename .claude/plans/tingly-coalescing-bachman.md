# Fix Schedule Windowing + Full-Slide Fill

## Context

Two bugs to fix in the schedule slide:

1. **Wrong windowing**: Should show all 12 weeks of the current Q + only the *last 1 week* of the previous Q. Currently shows last 4 prev-Q weeks and stops at the current week instead of the end of the Q.
2. **Schedule doesn't fill the slide**: Cells have a fixed 76px height so the grid floats in the top half; it should expand to use the full available height of the slide.

---

## File to Change

`scripts/project_management/milestones.py`

---

## Change 1 — Windowing logic (lines ~921–930)

```python
# Before
q_end     = min(n_items, q_start + Q_SIZE - 1)
first_idx = max(1, q_start - 4) if q_num > 0 else q_start

# After
q_end     = q_start + Q_SIZE - 1          # always full current Q (empty weeks get blank cells)
first_idx = max(1, q_start - 1) if q_num > 0 else q_start   # only last 1 prev-Q week
```

Empty weeks render fine already: `schedule.get(idx, {})` returns `{}` → blank cell.

**Result for BP CVL (current W16, Q2 = W13–W24):**
- W12: prev-Q (blue/indigo, faded) — 1 cell
- W13–W15: past this Q (gray, faded) — 3 cells
- W16: current (purple) — 1 cell
- W17–W24: upcoming (light purple) — 8 cells
- **Total: 13 cells across W12–W24**

---

## Change 2 — CSS: schedule fills the full slide

The fix: make `.eng-body` a column flex container, `.schedule-grid` flex-grows to fill it, and rows stretch to distribute available height equally instead of being fixed at 76px.

```css
/* Before */
.eng-body {
  flex: 1; overflow: hidden; padding: 20px 40px;
}
.schedule-grid {
  display: grid; gap: 8px;
  grid-auto-rows: 76px;
}

/* After */
.eng-body {
  flex: 1; overflow: hidden; padding: 20px 40px;
  display: flex; flex-direction: column;
}
.schedule-grid {
  display: grid; gap: 8px;
  flex: 1;
  align-content: stretch;
}
```

`align-content: stretch` makes CSS grid distribute its implicit rows evenly to fill the available height. Removing `grid-auto-rows: 76px` allows the rows to resize dynamically.

---

## Verification

```bash
uv run scripts/project_management/milestones.py --notion-md /tmp/notion_bp_cvl.md bp cvl_agentic
# Open ~/Downloads/weekly-bp-cvl_agentic-20260320.html
# Confirm:
#   - Schedule shows W12 + W13–W24 (13 cells total, 4 columns → 4 rows)
#   - Grid fills the full slide body top-to-bottom
#   - W12 = blue/faded, W13–15 = gray/faded, W16 = purple, W17–24 = light purple
```
