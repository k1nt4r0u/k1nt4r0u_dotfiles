#!/bin/bash

text=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)
[ -z "$text" ] && text="No music playing"

maxlen=25
if [ ${#text} -gt $maxlen ]; then
    i=$(($(date +%s) % (${#text} - $maxlen + 1)))
    text="${text:$i:$maxlen}"
fi

echo "$text"
