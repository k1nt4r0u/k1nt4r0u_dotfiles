#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
FILE="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FULLPATH="$DIR/$FILE"
mkdir -p "$DIR"
if [ "$1" == "full" ]; then
    grim "$FULLPATH"
    cat "$FULLPATH" | wl-copy
else
    GEOM=$(slurp)
    if [ -z "$GEOM" ]; then exit 1; fi
    grim -g "$GEOM" "$FULLPATH"
    cat "$FULLPATH" | wl-copy
fi
notify-send "Try HardeR!" "$FILE" -i "$FULLPATH"
