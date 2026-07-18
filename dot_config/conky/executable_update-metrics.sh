#!/bin/sh
# Background WEATHER fetcher for the conky dashboard (weather only — time and
# timezone are handled by the OS: systemd-timesyncd + tzupdate).
#
# Conky must not fetch weather directly: its ${exec}/${execi} calls run
# synchronously in the render loop, so a slow request freezes the whole panel.
# This loop writes to cache files that conky reads instantly with `cat`.
# Launched from bspwmrc; refreshes every 30 minutes. Keeps the last good value
# when a fetch fails rather than blanking it.

CACHE="$HOME/.cache"
mkdir -p "$CACHE"

put() { [ -n "$2" ] && printf '%s' "$2" > "$CACHE/$1"; }

while :; do
    put conky-w-here "$(curl -s --max-time 10 'https://wttr.in/?format=%t+%C' 2>/dev/null)"; sleep 3
    put conky-w-mvd  "$(curl -s --max-time 10 'https://wttr.in/Montevideo?format=%t+%C' 2>/dev/null)"; sleep 3
    put conky-w-pde  "$(curl -s --max-time 10 'https://wttr.in/Punta+del+Este?format=%t+%C' 2>/dev/null)"
    sleep 1800
done
