#!/bin/sh

# Merge Xresources
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Set keyboard repeat rate
xset r rate 300 50

# Disable screen blanking/DPMS
xset s off
xset -dpms

# Start bspwm
exec bspwm
