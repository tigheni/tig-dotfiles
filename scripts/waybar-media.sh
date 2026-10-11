#!/bin/sh
# Waybar custom/media: show what any MPRIS player (Spotify, browsers, mpv) is
# playing. A paused player stays shown for $idle_seconds, after which the
# module falls back to a rotating quote, as it does when no player exists.

idle_seconds=300
rotate_seconds=300
stamp="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-media-paused-since"

escape() {
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

quote() {
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
    text=$(printf '%s\n' "$quotes" | sed -n "${index}p" | escape)
    jq -cn --arg t "<i>$text</i>" '{text: $t, alt: "idle", class: "idle", tooltip: "Nothing playing"}'
    exit 0
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
