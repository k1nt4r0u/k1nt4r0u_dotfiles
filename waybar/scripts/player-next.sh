#!/bin/bash

STATE_FILE="/tmp/waybar_last_player"

# 1. Check for Playing
for player in $(playerctl -l 2>/dev/null); do
    if playerctl -p "$player" status 2>/dev/null | grep -q "Playing"; then
        playerctl -p "$player" next
        exit 0
    fi
done

if mpc status &>/dev/null && mpc status | grep -q "\[playing\]"; then
    mpc next
    exit 0
fi

# 2. State
if [ -f "$STATE_FILE" ]; then
    last_source=$(cat "$STATE_FILE")
    if [ "$last_source" == "mpd" ]; then
        mpc next
        exit 0
    elif [[ "$last_source" == mpris:* ]]; then
        player="${last_source#mpris:}"
        playerctl -p "$player" next
        exit 0
    fi
fi

# 3. Fallback
mpc next
