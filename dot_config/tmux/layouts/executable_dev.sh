#!/bin/bash
# Dev layout: nvim (left 60%) | claude (top-right) | terminal (bottom-right)

# Start fresh - kill all panes except current
# (commented out for safety - uncomment if needed)
# tmux kill-pane -a

# Split vertically - creates right pane (40%), inheriting current directory
tmux split-window -h -p 40 -c "#{pane_current_path}"

# Now in the right pane, split it horizontally, inheriting directory
tmux split-window -v -p 50 -c "#{pane_current_path}"

# At this point we have 3 panes and we're in pane 2 (bottom-right)
# Let's use directional selection to be safe

# Go all the way left to the main pane
tmux select-pane -L
tmux send-keys "nvim" C-m

# Go right and up to top-right pane
tmux select-pane -R
tmux select-pane -U
tmux send-keys "claude" C-m

# This pane stays focused (claude)
