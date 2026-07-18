#!/bin/sh
# Pause the conky dashboard whenever its desktop isn't focused.
# A SIGSTOPed conky uses zero CPU, so the dashboard costs nothing while you
# work on other desktops and only "wakes up" when you look at it.
#
# Launched from bspwmrc. Runs for the life of the session.

TARGET="10"   # bspwm desktop name that holds the dashboard (super+0)

apply() {
    if [ "$(bspc query -D -d focused --names)" = "$TARGET" ]; then
        pkill -CONT -x conky
    else
        pkill -STOP -x conky
    fi
}

apply                                   # set correct state at startup
bspc subscribe desktop_focus | while read -r _; do
    apply
done
