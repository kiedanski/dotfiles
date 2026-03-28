# Plan: HITL Column Label Test for sap8 (and repeated-letters regression guard)

## Context

The original bug: the Standardize Tables HITL screen shows duplicate Excel column letters (e.g. "F" appearing twice), confusing the user. The root cause is `collect_amounts` producing two `ProcessedAmount` objects with the same `col_idx` (because the LLM returned duplicate `col_id` entries in Stage 1). Two guards were added in this branch — a retry in `classification.py` and a skip in `collect_amounts` — but there is no **end-to-end test** that verifies the full pipeline from classification → `collect_amounts` → `group_amounts` → `build_hitl_rows` and checks the final HITL column labels for correctness and uniqueness.

## What We're Building

A new test file `tests/transformations/standardize_tables/test_sap8_hitl.py` with two complementary tests:

### Test 1 — Deterministic HITL unit test (fast, no LLM)
- Uses the **real sap8 Excel file** (DVC, `@pytest.mark.dvc`) read via `pd.read_excel`
- Uses a **hardcoded correct classification** for sap8 (matching what the LLM should produce: 2 entity, 1 account_code, 1 account_name, 1 other, 6 amounts at col_ids 5–10)
- Builds `column_letter_map` via range arithmetic (`extraction_range="A4:K2033"`, `metadata_df=pd.DataFrame()`) — no LlamaCloud needed, fallback in `build_column_label` computes F→K from range + col_idx
- Calls `collect_amounts` → `group_amounts` → `build_hitl_rows`
- Asserts:
  - Exactly 6 HITL rows are produced
  - All `Column` values are unique (the core repeated-letters regression guard)
  - The Column labels contain F, G, H, I, J, K (in any order)
  - `date` on all rows is `"2022-01-31"` (not the sentinel `"1985-05-02"`)

### Test 2 — Duplicate-injection regression guard (pure unit, no file/LLM)
- No real file needed — uses a small synthetic 11-column DataFrame
- Injects a **deliberately malformed classification** with a duplicate `col_id=5` (the exact failure mode of the original bug)
- Calls the same pipeline
- Asserts:
  - Only **1 row** for col_id=5 appears (duplicate is dropped by the `seen_col_idxes` guard)
  - All Column values are unique

## Key Code Paths to Invoke

| Function | File | Notes |
|---|---|---|
| `collect_amounts` | `src/…/standardize_tables/standardization.py:146` | takes `classification`, `raw_data`, `metadata_df`, `supported_index`, `full_date` |
| `group_amounts` | `src/…/standardize_tables/standardization.py:300` | takes `list[ProcessedAmount]` |
| `build_hitl_rows` | `src/…/standardize_tables/amount_groups_hitl.py:146` | takes `groups_needing_selection` list of dicts |
| `build_column_label` | `src/…/standardize_tables/amount_groups_hitl.py:16` | uses `column_letter_map` + fallback to `compute_excel_letter_from_range` |

## groups_needing_selection dict structure (passed to build_hitl_rows)

```python
{
    "sheet_name": "Analysis 1",
    "group_key": f"{group.date}_{group.entity}",
    "temporal_key": group.date or "None",
    "entity": group.entity or "None",
    "amounts": group.amounts,          # list[ProcessedAmount]
    "column_letter_map": {},           # {} → triggers fallback to range arithmetic
    "extraction_range": "A4:K2033",   # used by fallback
}
```

## Hardcoded Classification for sap8

```python
CLASSIFICATION = {
    "columns": [
        {"col_id": 0, "field_kind": "entity"},
        {"col_id": 1, "field_kind": "entity"},
        {"col_id": 2, "field_kind": "account_code"},
        {"col_id": 3, "field_kind": "account_name"},
        {"col_id": 4, "field_kind": "other"},
        {"col_id": 5, "field_kind": "amount", "date": "2022-01-31", "entity": "", "currency": "", "reporting_period": "current", "is_debit": False, "is_credit": False},
        # ... col_ids 6–10 similarly
    ]
}
```

(Note: no `date` attributes needed in the hardcoded version — `full_date="2022-01-31"` in `collect_amounts` will fill them in via `date = col_dict.get("date", full_date) or full_date`)

## File to Create

`backend/tests/transformations/standardize_tables/test_sap8_hitl.py`

- `@pytest.mark.dvc` on Test 1 (reads real Excel file)
- No marker on Test 2 (pure synthetic data, always runs)

## Verification

```bash
# Fast regression guard (no DVC, no LLM):
uv run pytest tests/transformations/standardize_tables/test_sap8_hitl.py::test_duplicate_col_id_never_produces_duplicate_column_label -v

# Real-file HITL structure test:
uv run pytest tests/transformations/standardize_tables/test_sap8_hitl.py -v -m dvc

# Stress run (5×) to catch flakiness:
uv run pytest tests/transformations/standardize_tables/test_sap8_hitl.py -v -m dvc --stress 5
```
