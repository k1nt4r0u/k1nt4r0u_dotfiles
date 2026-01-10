#!/bin/bash

STATE_FILE="/tmp/waybar_last_player"

# Function to write MPD status
write_mpd() {
    title=$(mpc current -f %title%)
    artist=$(mpc current -f %artist%)
    if [ -n "$artist" ] && [ -n "$title" ]; then
        text="$title - $artist"
    elif [ -n "$title" ]; then
        text="$title"
    else
        text=$(mpc current)
    fi
    
    # Escape quotes in text to prevent JSON breakage
    text=$(echo "$text" | sed 's/"/\\"/g')

    # Get exact status
    if mpc status | grep -q "\[playing\]"; then
        alt="Playing"
        class="Playing"
    else
        alt="Paused"
        class="Paused"
    fi
    printf '{"text": "%s", "alt": "%s", "class": "%s"}\n' "$text" "$alt" "$class"
}

# Function to write MPRIS status
write_mpris() {
    local player="$1"
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [ "$status" = "Playing" ]; then
        alt="Playing"
        class="Playing"
    else
        alt="Paused"
        class="Paused"
    fi
    # Use playerctl's format, assuming it handles basic text. 
    # Warning: Double quotes in title might break this simple JSON structure if not escaped by playerctl.
    # We add a sed pipe to escape quotes in the output if playerctl doesn't do it automatically in the format string context.
    # Actually, playerctl format strings are raw. Let's capture output and format in bash to be safe, 
    # or trust the existing pattern. The existing pattern was:
    # playerctl ... --format '{"text": "{{title}} - {{artist}}"...}'
    # We will stick to that for now but update the alt/class dynamically.
    
    playerctl -p "$player" metadata --format "{\"text\": \"{{title}} - {{artist}}\", \"alt\": \"$alt\", \"class\": \"$class\"}" 2>/dev/null
}

# 1. Check for PLAYING players (Priority)
# Check MPRIS first
for player in $(playerctl -l 2>/dev/null); do
    if playerctl -p "$player" status 2>/dev/null | grep -q "Playing"; then
        echo "mpris:$player" > "$STATE_FILE"
        write_mpris "$player"
        exit 0
    fi
done

# Check MPD
if mpc status &>/dev/null && mpc status | grep -q "\[playing\]"; then
    echo "mpd" > "$STATE_FILE"
    write_mpd
    exit 0
fi

# 2. If nothing playing, check LAST ACTIVE
if [ -f "$STATE_FILE" ]; then
    last_source=$(cat "$STATE_FILE")
    
    if [ "$last_source" == "mpd" ]; then
        # Check if MPD is actually alive/paused (not stopped/cleared)
        if mpc status | grep -E -q "\[paused\]|\[playing\]"; then
            write_mpd
            exit 0
        fi
    elif [[ "$last_source" == mpris:* ]]; then
        player="${last_source#mpris:}"
        # Check if player still exists
        if playerctl -l 2>/dev/null | grep -q "$player"; then
             write_mpris "$player"
             exit 0
        fi
    fi
fi

# 3. Fallback: If last active is gone/invalid, find ANY paused
for player in $(playerctl -l 2>/dev/null); do
    if playerctl -p "$player" status 2>/dev/null | grep -q "Paused"; then
        echo "mpris:$player" > "$STATE_FILE"
        write_mpris "$player"
        exit 0
    fi
done

if mpc status &>/dev/null && mpc status | grep -q "\[paused\]"; then
    echo "mpd" > "$STATE_FILE"
    write_mpd
    exit 0
fi

# 4. Nothing
printf '{"text": "No music playing", "alt": "Stopped", "class": "Stopped"}\n'
