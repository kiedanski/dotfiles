#!/usr/bin/env bash

# Ensure X display is available (important when called from autorandr hooks)
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

echo "[$(date)] Polybar launch script starting..." >> /tmp/polybar-launch.log
echo "DISPLAY=$DISPLAY, XAUTHORITY=$XAUTHORITY" >> /tmp/polybar-launch.log

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# Small delay to ensure cleanup is complete
sleep 0.2

# Launch polybar on all ACTIVE monitors (connected with resolution)
if type "xrandr" > /dev/null; then
  for m in $(xrandr --query | grep " connected" | grep -oP "^[^ ]+ connected (primary )?[0-9]+" | cut -d" " -f1); do
    MONITOR=$m polybar --config=$HOME/.config/polybar/config.ini main >>/tmp/polybar-$m.log 2>&1 &
    echo "Launched polybar on $m"
  done
else
  polybar --config=$HOME/.config/polybar/config.ini main >>/tmp/polybar.log 2>&1 &
fi

# Wait a moment for polybar to initialize
sleep 0.5

echo "Polybar launched..."
echo "[$(date)] Polybar launch script completed" >> /tmp/polybar-launch.log
echo "" >> /tmp/polybar-launch.log
