#!/bin/bash
STATE_FILE="/tmp/waybar_last_player"
ART_FILE="/tmp/qs_album_art.jpg"

get_mpd() {
    local title=$(mpc current -f '%title%' 2>/dev/null)
    local artist=$(mpc current -f '%artist%' 2>/dev/null)
    local status_line=$(mpc status -f '' 2>/dev/null)
    local state="Stopped"
    echo "$status_line" | grep -q '\[playing\]' && state="Playing"
    echo "$status_line" | grep -q '\[paused\]' && state="Paused"
    local progress_info=$(echo "$status_line" | grep -oP '(\d+):(\d+)/(\d+):(\d+)\s+\((\d+)%\)' || true)
    local pos=$(echo "$progress_info" | grep -oP '^\d+:\d+' || echo "0:00")
    local dur=$(echo "$progress_info" | grep -oP '(?<=/)[0-9:]+' || echo "0:00")
    local pct=$(echo "$progress_info" | grep -oP '\d+(?=%)' || echo "0")
    mpc readpicture "$(mpc current -f '%file%' 2>/dev/null)" > "$ART_FILE" 2>/dev/null || true
    echo "source:mpd"
    echo "title:$title"
    echo "artist:$artist"
    echo "status:$state"
    echo "position:$pos"
    echo "duration:$dur"
    echo "progress:$pct"
    local dur_parts=(${dur//:/ })
    local dur_secs=$(( ${dur_parts[0]} * 60 + ${dur_parts[1]} ))
    echo "duration_secs:$dur_secs"
    [ -s "$ART_FILE" ] && echo "art:$ART_FILE" || echo "art:"
}

get_mpris() {
    local player="$1"
    local state=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
    local title=$(playerctl -p "$player" metadata title 2>/dev/null)
    local artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
    local art_url=$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null)
    local pos_us=$(playerctl -p "$player" position 2>/dev/null || echo "0")
    local len_us=$(playerctl -p "$player" metadata mpris:length 2>/dev/null || echo "0")

    local pos_s=$(echo "$pos_us" | awk '{printf "%d", $1}')
    local len_s=$(echo "$len_us" | awk '{printf "%d", $1/1000000}')
    local pos_fmt=$(printf "%d:%02d" $((pos_s/60)) $((pos_s%60)))
    local dur_fmt=$(printf "%d:%02d" $((len_s/60)) $((len_s%60)))
    local pct=0
    [ "$len_s" -gt 0 ] 2>/dev/null && pct=$((pos_s * 100 / len_s))

    local art_path=""
    if [[ "$art_url" == file://* ]]; then
        art_path="${art_url#file://}"
    elif [[ -n "$art_url" ]]; then
        curl -sL "$art_url" -o "$ART_FILE" 2>/dev/null && art_path="$ART_FILE"
    fi

    echo "source:mpris:$player"
    echo "title:$title"
    echo "artist:$artist"
    echo "status:$state"
    echo "position:$pos_fmt"
    echo "duration:$dur_fmt"
    echo "progress:$pct"
    echo "duration_secs:$len_s"
    echo "art:$art_path"
}

# Priority: playing > last active > paused > nothing
for player in $(playerctl -l 2>/dev/null); do
    if playerctl -p "$player" status 2>/dev/null | grep -q "Playing"; then
        get_mpris "$player"; exit 0
    fi
done
if mpc status 2>/dev/null | grep -q '\[playing\]'; then
    get_mpd; exit 0
fi

if [ -f "$STATE_FILE" ]; then
    last=$(cat "$STATE_FILE")
    if [ "$last" = "mpd" ] && mpc status 2>/dev/null | grep -qE '\[paused\]|\[playing\]'; then
        get_mpd; exit 0
    elif [[ "$last" == mpris:* ]]; then
        p="${last#mpris:}"
        if playerctl -l 2>/dev/null | grep -q "$p"; then
            get_mpris "$p"; exit 0
        fi
    fi
fi

for player in $(playerctl -l 2>/dev/null); do
    if playerctl -p "$player" status 2>/dev/null | grep -q "Paused"; then
        get_mpris "$player"; exit 0
    fi
done
if mpc status 2>/dev/null | grep -qE '\[paused\]'; then
    get_mpd; exit 0
fi

echo "source:"
echo "title:"
echo "artist:"
echo "status:Stopped"
echo "position:0:00"
echo "duration:0:00"
echo "progress:0"
echo "duration_secs:0"
echo "art:"
