#!/bin/sh
# Waybar custom/media: show what any MPRIS player (Spotify, browsers, mpv) is
# playing. A paused player stays shown for $idle_seconds, after which the
# module falls back to a quote, as it does when no player exists.
# `waybar-media.sh toggle` hides/shows Waybar; each hide swaps in the next
# quote from a pool of random zenquotes.io quotes (refilled 50 at a time), so
# a fresh one is waiting when the bar comes back and none are spent unseen.

idle_seconds=300
rotate_seconds=300
stamp="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-media-paused-since"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
quote_file="$cache_dir/quote.json"
quote_pool="$cache_dir/quotes.json"

escape() {
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

next_quote() {
    mkdir -p "$cache_dir"
    if [ "$(jq length "$quote_pool" 2>/dev/null || echo 0)" -eq 0 ]; then
        if curl -fsS -m 10 https://zenquotes.io/api/quotes 2>/dev/null |
            jq -ce '[.[] | select(.q and .a) | {q, a}] | select(length > 0)' >"$quote_pool.tmp" 2>/dev/null; then
            mv "$quote_pool.tmp" "$quote_pool"
        fi
    fi
    if jq -ce '.[0] // empty' "$quote_pool" >"$quote_file.tmp" 2>/dev/null; then
        mv "$quote_file.tmp" "$quote_file"
        jq -c '.[1:]' "$quote_pool" >"$quote_pool.tmp" && mv "$quote_pool.tmp" "$quote_pool"
    fi
    rm -f "$quote_file.tmp" "$quote_pool.tmp"
    pkill -RTMIN+13 -x 'waybar|\.waybar-wrapped'
}

# waybar-launch.sh removes $hidden_flag, as Waybar always starts visible.
toggle() {
    pkill -SIGUSR1 -x 'waybar|\.waybar-wrapped' || exit 0
    if [ -f "$hidden_flag" ]; then
        rm -f "$hidden_flag"
    else
        touch "$hidden_flag"
        next_quote
    fi
    exit 0
}

hidden_flag="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar/hidden"
[ "${1:-}" = toggle ] && toggle

# Print a quote line; the tooltip holds the whole quote, wrapped, for when
# max-length truncates it on the bar.
show_quote() {
    text=$(printf '%s' "$1" | escape)
    tooltip=$(printf '%s\n' "${1% — *}" | fold -s -w 60 | sed 's/ *$//' | escape)
    case $1 in *" — "*) tooltip=$(printf '%s\n— %s' "$tooltip" "$(printf '%s' "${1##* — }" | escape)") ;; esac
    jq -cn --arg t "<i>$text</i>" --arg tt "$tooltip" '{text: $t, alt: "idle", class: "idle", tooltip: $tt}'
    exit 0
}

quote() {
    line=$(jq -r '"\(.q) — \(.a)"' "$quote_file" 2>/dev/null)
    [ -z "$line" ] || show_quote "$line"

    quotes='Simplicity is prerequisite for reliability. — Edsger Dijkstra
Make it work, make it right, make it fast. — Kent Beck
Talk is cheap. Show me the code. — Linus Torvalds
The best way to predict the future is to invent it. — Alan Kay
Premature optimization is the root of all evil. — Donald Knuth
Programs must be written for people to read. — Harold Abelson
First, solve the problem. Then, write the code. — John Johnson
Discipline is choosing between what you want now and what you want most.
Well done is better than well said. — Benjamin Franklin
It always seems impossible until it is done. — Nelson Mandela
Do one thing and do it well. — Unix philosophy
Stay hungry, stay foolish. — Stewart Brand
The obstacle is the way. — Marcus Aurelius
Slow is smooth, smooth is fast.
Small steps every day.'
    count=$(printf '%s\n' "$quotes" | wc -l)
    index=$(($(date +%s) / rotate_seconds % count + 1))
    show_quote "$(printf '%s\n' "$quotes" | sed -n "${index}p")"
}

players=$(playerctl --all-players metadata --format '{{status}} {{playerInstance}}' 2>/dev/null)
player=$(printf '%s\n' "$players" | sed -n 's/^Playing //p' | head -n 1)

if [ -n "$player" ]; then
    rm -f "$stamp"
    status=playing
else
    player=$(printf '%s\n' "$players" | sed -n 's/^Paused //p' | head -n 1)
    [ -n "$player" ] || quote
    now=$(date +%s)
    [ -f "$stamp" ] || echo "$now" >"$stamp"
    [ $((now - $(cat "$stamp"))) -lt "$idle_seconds" ] || quote
    status=paused
fi

tab=$(printf '\t')
IFS="$tab" read -r title position length artist <<EOF
$(playerctl --player="$player" metadata --format "{{title}}$tab{{duration(position)}}$tab{{duration(mpris:length)}}$tab{{artist}}" 2>/dev/null)
EOF

text=$(printf '%s' "$title" | escape)
[ -z "$length" ] || text="$text $position/$length"
tooltip=$(printf '%s (%s):\n%s - %s' "${player%%.*}" "$status" "$artist" "$title" | escape)

jq -cn --arg t "$text" --arg s "$status" --arg tt "$tooltip" '{text: $t, alt: $s, class: $s, tooltip: $tt}'
