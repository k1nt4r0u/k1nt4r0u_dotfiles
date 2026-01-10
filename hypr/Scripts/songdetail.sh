#!/bin/bash

# Robust song info script - tries MPD first, then MPRIS players
# Fallback chain: MPD → mpd-mpris → other MPRIS players

get_mpd_song() {
    # Try direct MPD connection
    if mpc current -f '%artist%   %title%' 2>/dev/null | grep -q .; then
        mpc current -f '%artist%   %title%' 2>/dev/null
        return 0
    fi
    return 1
}

get_mpris_mpd() {
    # Try MPD through MPRIS (mpd-mpris daemon)
    if playerctl -p mpd metadata --format '{{artist}}   {{title}}' 2>/dev/null | grep -q .; then
        playerctl -p mpd metadata --format '{{artist}}   {{title}}' 2>/dev/null
        return 0
    fi
    return 1
}

get_any_mpris() {
    # Try any available MPRIS player
    if playerctl metadata --format '{{artist}}   {{title}}' 2>/dev/null | grep -q .; then
        playerctl metadata --format '{{artist}}   {{title}}' 2>/dev/null
        return 0
    fi
    return 1
}

# Try sources in order of preference
if song_info=$(get_mpd_song); then
    echo "$song_info"
elif song_info=$(get_mpris_mpd); then
    echo "$song_info"
elif song_info=$(get_any_mpris); then
    echo "$song_info"
else
    echo "No song playing"
fi
