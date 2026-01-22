# Tmux + Git Worktree Workflow

**Created:** 2026-01-21
**Purpose:** Efficient project and worktree management with tmux sessions

---

## Overview

This workflow integrates tmux, git worktrees, and fzf to provide a seamless development environment where:
- Each git worktree gets its own tmux session
- Quick switching between projects and branches
- Automatic layout setup (nvim | claude | terminal)
- Frecency-based sorting (most used items appear first)
- History tracking for branch names and selections

---

## Components

### Scripts

**`~/.local/bin/dev`**
- Creates git worktrees at `project/worktrees/<branch-name>`
- Handles existing branches (local/remote) and new branch creation
- Creates tmux session named `<project>-<branch>`
- Applies dev layout automatically
- Usage: `dev <branch-name> [base-branch]`

**`~/.local/bin/tmux-picker`**
- Fuzzy finder for sessions and projects
- Shows existing tmux sessions with status indicators
- Lists available git repos in ~/workspace
- Creates worktrees with branch selection prompts
- Tracks usage history (frecency)
- Shell alias: `ts`

**`~/.config/tmux/layouts/dev.sh`**
- Sets up 3-pane layout: nvim (left 60%) | claude (top-right) | terminal (bottom-right)
- Focuses on claude pane
- Inherits current directory to all panes

### Tmux Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+a W` | Apply dev layout to current window |
| `Ctrl+a f` | Open session/project picker (popup) |
| `Ctrl+a X` | Kill current session (with confirmation) |
| `Ctrl+a r` | Reload tmux config |

### Cache Files

All stored in `~/.cache/tmux-picker/`:
- `session-history` - fzf search history for sessions
- `branch-history` - Previously used branch names
- `base-history` - Previously selected base branches
- `frecency` - Usage tracking (timestamp + item)

---

## Workflows

### Starting Work on a New Branch

**From outside tmux:**
```bash
cd ~/workspace/myproject
dev feature-auth main
```

**From anywhere with tmux-picker:**
```bash
ts                          # or Ctrl+a f inside tmux
# Select project
# Enter branch name: feature-auth
# Select base branch: main
# → Creates worktree + session, applies layout
```

**Result:**
- Worktree created at: `~/workspace/myproject/worktrees/feature-auth`
- Files copied (if specified in `.devrc`): `.env`, `.env.local`, etc.
- Session created: `myproject-feature-auth`
- Layout applied: nvim | claude | terminal
- Focus on claude pane

### Working on an Existing Branch

**With dev script:**
```bash
cd ~/workspace/myproject
dev existing-branch
# Automatically detects it exists, creates worktree + session
```

**With tmux-picker:**
```bash
Ctrl+a f
# Select project
# Shows list of existing branches (local + remote)
# Select the branch you want
# → Skips base branch prompt, creates worktree + session
```

### Switching Between Worktrees

**Using tmux-picker (Recommended):**
```bash
Ctrl+a f
# Shows existing sessions with indicators:
# ● myproject-feature-auth    (current session)
# ○ myproject-main            (other session)
# ○ myproject-bugfix-123
# Select one → instantly switch
```

**Manual tmux commands:**
```bash
tmux ls                     # List all sessions
tmux switch -t session-name # Switch to session
```

### Creating New Project Session

**For main project directory (no worktree):**
```bash
cd ~/workspace/newproject
dev main
# Creates session for the main project directory
```

**Then create worktrees from within:**
```bash
dev feature-1
dev feature-2
# Each gets its own session
```

### Quick Layout Application

If you're already in a tmux window and want to apply the dev layout:
```bash
Ctrl+a W
# Instantly splits into nvim | claude | terminal
```

---

## Configuration

### Project-Level Config (.devrc)

Create a `.devrc` file in any project to set defaults:

**~/workspace/myproject/.devrc:**
```bash
# Default base branch for new branches
BASE_BRANCH=develop

# Files to copy to new worktrees (space-separated)
COPY_FILES=".env .env.local config/secrets.yml"
```

**Common examples:**
```bash
# For projects using 'develop'
BASE_BRANCH=develop

# For projects using 'master'
BASE_BRANCH=master

# For monorepos with different patterns
BASE_BRANCH=trunk

# Copy environment files and secrets
COPY_FILES=".env .env.local"

# Copy multiple config files
COPY_FILES=".env config/database.yml config/secrets.yml"
```

**File Copying:**
- Files are copied from the repo root to the same relative path in the worktree
- Directories are created automatically if needed
- Non-existent files are skipped with a warning
- Useful for `.env` files, config files, secrets that shouldn't be committed

### Customizing the Layout

Edit `~/.config/tmux/layouts/dev.sh` to change:
- Pane sizes (currently 60/40 split)
- Which programs start in which pane
- Which pane gets focus
- Add more panes

**Example modifications:**
```bash
# Change split ratio to 70/30
tmux split-window -h -p 30

# Start different program
tmux send-keys "lazygit" C-m

# Focus on nvim instead of claude
tmux select-pane -t 0
```

### Creating Additional Layouts

Create new layout scripts in `~/.config/tmux/layouts/`:

**Example: `~/.config/tmux/layouts/fullstack.sh`**
```bash
#!/bin/bash
# 3 panes: editor | frontend dev server | backend dev server
tmux split-window -h -p 50 -c "#{pane_current_path}"
tmux split-window -v -p 50 -c "#{pane_current_path}"
tmux select-pane -t 0
tmux send-keys "nvim" C-m
tmux select-pane -t 1
tmux send-keys "npm run dev" C-m
tmux select-pane -t 2
tmux send-keys "python manage.py runserver" C-m
```

Bind it in tmux.conf:
```bash
bind-key F run-shell "~/.config/tmux/layouts/fullstack.sh"
```

---

## Visual Indicators

### Session Picker

```
● Yggdrasil-feature-auth    ← Active session (you're here)
○ Yggdrasil-main            ← Inactive session
○ otherproject-dev          ← Inactive session
  newproject                ← Available project (no session yet)
  anotherproject           ← Available project
```

### Branch Picker

```
  main                      ← Existing branches
  develop
  feature-auth
  bugfix-123
  new-feature-name          ← Recent from history
```

Type to filter or create new branch name.

---

## Frecency System

The picker learns your patterns and surfaces frequently/recently used items first.

**How it works:**
- Every selection is recorded with a timestamp
- More recent = higher score
- More frequent = higher score
- Scores decay over time (exponential)
- Old entries (30+ days) are auto-cleaned

**Result:**
Your top-used projects/sessions appear at the top of the picker, making navigation faster over time.

---

## Common Patterns

### Daily Workflow

```bash
# Morning: Jump into yesterday's work
ts
# Your active sessions from yesterday appear at top
# Select and continue

# Need to switch branches?
Ctrl+a f
# Select existing session or create new worktree

# Done with a feature?
Ctrl+a X    # Kill session (confirms first)
# Worktree remains on disk, can recreate session later
```

### Working on Multiple Features

```bash
# Create worktrees for each feature
dev feature-1 main
Ctrl+a f → dev feature-2 main
Ctrl+a f → dev feature-3 main

# Switch between them instantly
Ctrl+a f
# All three sessions listed at top (frecency)
```

### Code Review Workflow

```bash
# Checkout PR branch
dev pr-branch-name

# Review in nvim, test in terminal
# When done, kill session
Ctrl+a X
```

---

## Troubleshooting

### Session not showing in picker
```bash
# Verify session exists
tmux ls

# If it exists but doesn't show, reload cache
rm ~/.cache/tmux-picker/frecency
```

### Layout not applying correctly
```bash
# Make sure you're in a fresh window (only 1 pane)
Ctrl+a c      # Create new window
Ctrl+a W      # Apply layout

# Or specify directory first
cd ~/workspace/myproject/worktrees/branch
Ctrl+a W
```

### Worktree already exists error
```bash
# List existing worktrees
git worktree list

# Remove if needed
git worktree remove worktrees/branch-name

# Then recreate
dev branch-name
```

### Branch name not in history
History only tracks branches you've created/selected through the picker.
To manually add:
```bash
echo "my-branch-name" >> ~/.cache/tmux-picker/branch-history
```

### Clear all history
```bash
rm -rf ~/.cache/tmux-picker/
# Will rebuild on next use
```

### Popup doesn't appear
Your tmux version might not support popups (requires 3.2+):
```bash
tmux -V    # Check version

# If old, change keybinding in tmux.conf:
bind-key f run-shell "tmux new-window tmux-picker"
```

---

## File Structure

```
~/.local/bin/
├── dev               # Worktree + session creator
└── tmux-picker       # Session/project picker (alias: ts)

~/.config/tmux/
├── tmux.conf         # Config with keybindings
└── layouts/
    └── dev.sh        # 3-pane dev layout

~/.config/zsh/custom/
└── alias.zsh         # Contains: alias ts='tmux-picker'

~/.cache/tmux-picker/
├── session-history   # fzf query history
├── branch-history    # Branch name history
├── base-history      # Base branch history
└── frecency          # Usage tracking

~/workspace/
└── <project>/
    ├── .devrc        # Optional: project defaults
    └── worktrees/    # Created automatically
        ├── branch-1/
        ├── branch-2/
        └── branch-3/
```

---

## Tips & Tricks

### Quickly recreate a session for existing worktree
```bash
cd ~/workspace/project/worktrees/branch-name
dev branch-name
# Detects worktree exists, just creates session
```

### Use tab completion for dev command
The `dev` script accepts branch names - your shell's git completion should work:
```bash
dev feat<TAB>    # Completes to existing branch names
```

### Batch create worktrees
```bash
for branch in feature-1 feature-2 feature-3; do
  dev $branch main
done
```

### Clean up old worktrees
```bash
# List all worktrees
git worktree list

# Remove unused ones
git worktree remove worktrees/old-branch
```

### Automatically copy .env files to new worktrees
```bash
# In your project root, create .devrc:
echo 'COPY_FILES=".env .env.local"' > .devrc

# Now all new worktrees will have these files copied automatically
dev new-branch
# → Creates worktree with .env files already in place
```

### Export session list
```bash
tmux ls > ~/my-sessions.txt
```

### Quick access to most-used project
After using the picker a few times, your top project will always be first:
```bash
Ctrl+a f
<Enter>    # Just press Enter to select top item
```

---

## Integration Ideas

### VS Code
Open nvim's current file in VS Code:
```vim
" In nvim, add to config:
nnoremap <leader>c :!code %<CR>
```

### Git Hooks
Auto-switch to session when pushing:
```bash
# .git/hooks/pre-push
#!/bin/bash
SESSION_NAME="$(basename $(git rev-parse --show-toplevel))-$(git branch --show-current)"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session exists: $SESSION_NAME"
fi
```

### Status Bar
Show current worktree in tmux status:
```bash
# In tmux.conf:
set -g status-right "#(basename #{pane_current_path})"
```

---

## Advanced Usage

### Multiple Workspace Directories

Edit `tmux-picker` to scan multiple directories:
```bash
# In ~/.local/bin/tmux-picker, change:
WORKSPACE="$HOME/workspace:$HOME/projects:$HOME/clients"
```

Then update `get_available_projects()` to split on `:` and scan each.

### Auto-start tmux on login

Add to `~/.zshrc`:
```bash
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
  tmux attach -t default || tmux new -s default
fi
```

### Project templates

Create template layouts for different project types:
```bash
~/.config/tmux/layouts/
├── dev.sh           # General dev
├── frontend.sh      # Frontend (editor + dev server + tests)
├── backend.sh       # Backend (editor + server + logs)
└── fullstack.sh     # Fullstack (editor + frontend + backend)
```

Detect project type in `dev` script and apply appropriate layout.

---

## Changelog

### 2026-01-21
- Initial setup
- Created dev script with worktree management
- Created tmux-picker with frecency
- Added dev layout (nvim | claude | terminal)
- Added history tracking for branches and sessions
- Added .devrc support for project defaults

---

## References

- [Git Worktree Docs](https://git-scm.com/docs/git-worktree)
- [Tmux Manual](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [FZF GitHub](https://github.com/junegunn/fzf)

---

**Questions?** Check the troubleshooting section or explore the scripts directly - they're well-commented.
