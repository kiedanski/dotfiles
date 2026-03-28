# Implementation Plan: 4-State Processing Status

## Context

Items currently have two overlapping tracking mechanisms:
- `included` (BooleanField, default=False) — controls what appears in the newsletter preview
- `status` ('unprocessed'/'reviewed'/'assigned') — workflow tracking, not visible in UI

This creates confusion: editors can't tell at a glance where an item is in the editorial process, and everything defaults to "not showing" with no clear path forward. The user wants a single, unified status with 4 states that drives both editorial tracking AND preview rendering.

## New States

| Status | Meaning | Shows in preview |
|--------|---------|-----------------|
| `not_processed` | Default — raw item, hasn't been reviewed | No |
| `processed` | Filled in (who/what/template) but not confirmed | No |
| `included` | Approved for newsletter | Yes |
| `discarded` | Explicitly rejected | No |

Only `included` items appear in the newsletter preview.

---

## File Changes

### 1. `apps/newsletter/models/item.py`

Replace `status` field choices:
```python
STATUS_CHOICES = [
    ('not_processed', 'Not Processed'),
    ('processed', 'Processed'),
    ('included', 'Included'),
    ('discarded', 'Discarded'),
]
status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='not_processed', db_index=True)
```

Override `save()` to keep `included` in sync (so existing ORM queries still work without touching preview/task code):
```python
def save(self, *args, **kwargs):
    self.included = (self.status == 'included')
    super().save(*args, **kwargs)
```

Remove `reviewed_at` and `reviewed_by` fields (no longer needed).

### 2. Migration (new file)

Two parts:
1. Schema: update `status` max_length/choices, drop `reviewed_at`/`reviewed_by`
2. Data migration:
   - `included=True` → `status='included'`
   - `included=False` AND `selected_template` is set → `status='processed'`
   - `included=False` AND `selected_template` is null → `status='not_processed'`

### 3. `apps/newsletter/views/htmx_views.py`

Replace `ItemToggleInclusionView` with `ItemUpdateStatusView`:
```python
class ItemUpdateStatusView(LoginRequiredMixin, View):
    def post(self, request, pk):
        item = get_object_or_404(NewsletterItem, pk=pk)
        new_status = request.POST.get('status')
        if new_status in dict(NewsletterItem.STATUS_CHOICES):
            item.status = new_status
            item.save()
        return render(request, 'newsletter/partials/item_card.html', {'item': item})
```

### 4. `apps/newsletter/urls.py`

Replace `item_toggle` URL with `item_update_status`:
```python
path('item/<int:pk>/status/', ItemUpdateStatusView.as_view(), name='item_update_status'),
```

### 5. `apps/newsletter/templates/newsletter/partials/item_card.html`

Replace the inclusion checkbox with a compact status `<select>` using HTMX:
```html
<select name="status"
        hx-post="{% url 'newsletter:item_update_status' item.pk %}"
        hx-target="#item-{{ item.pk }}"
        hx-swap="outerHTML"
        hx-trigger="change"
        class="form-select form-select-sm status-{{ item.status }}"
        style="width: auto;">
    {% for val, label in item.STATUS_CHOICES %}
        <option value="{{ val }}" {% if item.status == val %}selected{% endif %}>{{ label }}</option>
    {% endfor %}
</select>
```

Add CSS for status colors (in the template's `<style>` block or edition_detail.html):
```css
select.status-not_processed { color: #6c757d; background-color: #f8f9fa; }
select.status-processed      { color: #664d03; background-color: #fff3cd; }
select.status-included       { color: #0a3622; background-color: #d1e7dd; }
select.status-discarded      { color: #842029; background-color: #f8d7da; }
```

Update item container to reflect status visually:
```html
<div class="list-group-item
    {% if item.status == 'discarded' %}opacity-50{% endif %}
    {% if item.status == 'included' %}border-start border-success border-3{% endif %}"
```

### 6. `apps/newsletter/views/edition_views.py`

Update `UnprocessedItemsView` filter (line ~422):
```python
# Old: status='unprocessed'
items = NewsletterItem.objects.filter(status='not_processed')
```

Preview rendering already uses `edition.get_items_by_category()` → filters `included=True` → still works because `save()` syncs `included` from `status`. No change needed there.

### 7. `integrations/airtable.py`

Currently sets `status='assigned'` (line ~331) or `status='unprocessed'` (line ~366) on newly created items. Both values will no longer exist.

Update all Airtable item creation to use `status='not_processed'`:
```python
# Old:
'status': 'assigned',   # or 'unprocessed'
# New:
'status': 'not_processed',
```

Airtable import is create-only (never updates existing items), so this only affects new items pulled in. Existing processed/included items on Railway are untouched.

### 8. `.opencode/skills/update-item/SKILL.md`

Update the listing query:
```python
items = NewsletterItem.objects.filter(
    edition__month=2, edition__year=2026,
    status__in=['not_processed', 'processed'],
).exclude(raw_content='').order_by('category', 'pk')
```

Update exclusion instructions: use `item.status = 'discarded'; item.save()` instead of `item.included = False`.

---

## Data Migration Logic

`included=True` was the old default — it cannot be trusted as a signal for "editor approved". But `included=False` was explicitly set by the editor (expired deadlines, manual exclusions), so those map to `discarded`.

Priority order (first match wins):

1. `included=False` → `discarded`
2. `who` or `what` or `details` is non-empty → `processed`
3. Everything else → `not_processed`

Nothing is migrated to `included` — editors will mark items as `included` manually going forward.

```python
def migrate_status(apps, schema_editor):
    Item = apps.get_model('newsletter', 'NewsletterItem')
    for item in Item.objects.all():
        if not item.included:
            new_status = 'discarded'
        elif item.who or item.what or item.details:
            new_status = 'processed'
        else:
            new_status = 'not_processed'
        Item.objects.filter(pk=item.pk).update(status=new_status)
```

---

## Verification

1. Push to Railway and run migrations
2. Open edition detail — items should show colored status dropdowns
3. Change an item to `included` — should immediately appear in preview
4. Change back to `processed` — should disappear from preview
5. Verify Slack task still counts correctly (uses `included=True`, synced by `save()`)
