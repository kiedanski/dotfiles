#!/bin/bash

# Get actual connected monitors from xrandr
actual_monitors=$(xrandr --query | grep " connected" | grep -oP "^[^ ]+ connected (primary )?[0-9]+" | cut -d" " -f1)
actual_count=$(echo "$actual_monitors" | wc -l)

# Remove orphaned monitors from bspwm
for mon in $(bspc query -M --names); do
    if ! echo "$actual_monitors" | grep -q "^${mon}$"; then
        bspc monitor "$mon" -r
        echo "Removed orphaned monitor: $mon"
    fi
done

# Detect remaining monitors in bspwm
monitor_count=$(bspc query -M | wc -l)

if [ "$monitor_count" -eq 2 ]; then
    # Two monitors: split workspaces 1-5 and 6-10
    monitor1=$(bspc query -M | sed -n 1p)
    monitor2=$(bspc query -M | sed -n 2p)
    
    bspc monitor "$monitor1" -d 1 2 3 4 5
    bspc monitor "$monitor2" -d 6 7 8 9 10
    
    echo "Two monitors detected: workspaces 1-5 and 6-10 split"
else
    # Single monitor: consolidate all workspaces
    monitor=$(bspc query -M | head -n 1)

    # Remove all existing desktop assignments and reassign
    bspc monitor "$monitor" -d 1 2 3 4 5 6 7 8 9 10

    echo "Single monitor detected: all workspaces on one monitor"
fi

# Restart polybar to match monitor configuration
$HOME/.config/polybar/launch.sh
