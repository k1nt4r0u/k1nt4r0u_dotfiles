#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
FILE="screenshot_$(date +%Y-%m-%d_%H-%M-%S).jpg"
FULLPATH="$DIR/$FILE"
mkdir -p "$DIR"

if [ "$1" == "full" ]; then
    grim -t jpeg -q 60 "$FULLPATH" &
    grim - | wl-copy

else
    
    GEOM=$(slurp)
    if [ -z "$GEOM" ]; then exit 1; fi
    
    grim -g "$GEOM" -t jpeg -q 60 "$FULLPATH" &
    
    grim -g "$GEOM" - | wl-copy

fi

wait
notify-send "Chụp xong rồi tml!" "Lưu tại $FILE" -i "$FULLPATH"
