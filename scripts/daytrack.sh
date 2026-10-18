#!/bin/sh
# daytrack: automatic, local time tracking built on Hyprland focus events.
# Logs which window has focus into ~/.local/share/daytrack/YYYY-MM-DD.tsv,
# sorts it into categories and projects, nudges you about breaks and
# distractions, and feeds a Waybar module. Run `daytrack.sh help`.

conf_dir=${XDG_CONFIG_HOME:-$HOME/.config}/daytrack
data_dir=${XDG_DATA_HOME:-$HOME/.local/share}/daytrack
run_dir=${XDG_RUNTIME_DIR:-/tmp}/daytrack
rules=$conf_dir/rules.tsv

GOAL_MIN=300
PRODUCTIVE="work ai learn write"
BREAK_AFTER_MIN=90
BREAK_REPEAT_MIN=30
DISTRACT_CATS="fun"
DISTRACT_AFTER_MIN=20
STREAK_GRACE_MIN=3
DEEP_MIN=25
PRIVATE_CATS=""
RECAP=1
TICK=15
# shellcheck source=/dev/null
[ -r "$conf_dir/daytrack.conf" ] && . "$conf_dir/daytrack.conf"

mkdir -p "$data_dir" "$run_dir"
TAB=$(printf '\t')

now() { date +%s; }
today() { date +%F; }
day_of() { date -d "@$1" +%F; }
midnight() { date -d "$1" +%s; }
log_of() { printf '%s/%s.tsv\n' "$data_dir" "$1"; }
has_word() { case " $1 " in *" $2 "*) return 0 ;; esac; return 1; }
clean() { printf '%s' "$1" | tr '\t\r\n' '   '; }

fmt() {
    h=$(($1 / 3600)) m=$(($1 % 3600 / 60))
    if [ "$h" -gt 0 ]; then printf '%dh%02d' "$h" "$m"; else printf '%dm' "$m"; fi
}

notify() { notify-send -a daytrack -i appointment-soon "$1" "$2" 2>/dev/null; }
refresh_bar() { pkill -RTMIN+14 waybar 2>/dev/null; }

daemon_alive() {
    [ -r "$run_dir/pid" ] && kill -0 "$(cat "$run_dir/pid")" 2>/dev/null
}

# --- classification ---------------------------------------------------------

project_of() {
    case $1 in
    code | code-url-handler | cursor)
        # VS Code title: "file - folder - Visual Studio Code"
        printf '%s\n' "$2" | awk -F' - ' '
            $NF ~ /Visual Studio Code|Cursor/ { if (NF >= 3) print $(NF-1); else if (NF == 2) print $1 }'
        ;;
    org.wezfurlong.wezterm)
        # The focused pane's working directory, reduced to its git repo name.
        # WezTerm prefixes the OS title with "[1/2] " when a window has tabs.
        dir=$(wezterm cli list --format json 2>/dev/null |
            T="$2" jq -r 'map(select(.is_active and (.window_title as $w | env.T | endswith($w)))) | .[0].cwd // empty' |
            sed 's|^file://[^/]*||; s|/$||')
        if [ -n "$dir" ] && [ "$dir" != "$HOME" ] && [ -d "$dir" ]; then
            root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root=$dir
            basename "$root"
        fi
        ;;
    esac
}

remember_project() {
    [ -n "$1" ] || return 0
    grep -qxF "$1" "$data_dir/projects" 2>/dev/null || printf '%s\n' "$1" >>"$data_dir/projects"
}

# A browser tab mentioning a known project (your app on localhost, its
# GitHub page) counts as work on that project.
match_project() {
    [ -s "$data_dir/projects" ] || return 0
    T=$1 awk 'BEGIN { t = tolower(ENVIRON["T"]) }
        length($0) >= 4 && index(t, tolower($0)) { print; exit }' "$data_dir/projects"
}

# Prints "category<TAB>project".
classify() {
    proj=$(project_of "$1" "$2") cat=
    case $1 in
    brave* | firefox* | chromium*)
        p=$(match_project "$2")
        [ -n "$p" ] && cat=work proj=$p
        ;;
    esac
    if [ -z "$cat" ] && [ -r "$rules" ]; then
        cat=$(C=$1 T=$2 awk -F'\t' '
            BEGIN { c = tolower(ENVIRON["C"]); t = tolower(ENVIRON["T"]) }
            /^#/ || NF < 3 { next }
            c ~ tolower($2) && ($3 == "*" || t ~ tolower($3)) { print $1; exit }' "$rules")
    fi
    printf '%s\t%s\n' "${cat:-other}" "$proj"
}

# --- analysis ---------------------------------------------------------------

# Segment lines for a day; today's includes the still-open segment.
data_for() {
    f=$(log_of "$1")
    [ -r "$f" ] && cat "$f"
    if [ "$1" = "$(today)" ] && daemon_alive && [ -r "$run_dir/current" ]; then
        awk -F'\t' -v OFS='\t' -v n="$(now)" '{ $2 = n; if ($4 == "-") $4 = ""; print }' "$run_dir/current"
    fi
}

# Modes: vals (one tab-separated summary line), report, timeline, projects, week.
analyze() {
    mode=$1 day=${2:-$(today)}
    color=0
    [ -t 1 ] && color=1
    awk -F'\t' -v mode="$mode" -v day0="$(midnight "$day")" -v dayname="$(date -d "$day" '+%a %d %b %Y')" \
        -v goalmin="$GOAL_MIN" -v prodlist="$PRODUCTIVE" -v grace="$STREAK_GRACE_MIN" \
        -v deepmin="$DEEP_MIN" -v color="$color" '
    function rep(ch, n,   s) { s = ""; while (n-- > 0) s = s ch; return s }
    # org.wezfurlong.wezterm -> wezterm
    function short(name) { sub(/^[a-z]+\.[a-z0-9-]+\./, "", name); return name }
    function fd(s,   h, m) {
        s = int(s); h = int(s / 3600); m = int(s % 3600 / 60)
        return h > 0 ? sprintf("%dh%02d", h, m) : sprintf("%dm", m)
    }
    function bar(v, max, w,   n) {
        if (max <= 0) max = 1
        n = int(v / max * w + 0.5); if (n > w) n = w
        return A rep("█", n) R D rep("░", w - n) R
    }
    function endstreak(   l) {
        if (sst == "") return
        l = plast - sst
        if (l >= deepmin) { deep++; deeptot += sprod }
        if (l > longest) longest = l
        sst = ""
    }
    function section(title, arr, total, limit, mark,   k, n) {
        if (length(arr) == 0) return
        printf "\n  %s%s%s\n", B, title, R
        PROCINFO["sorted_in"] = "@val_num_desc"
        n = 0
        for (k in arr) {
            if (++n > limit) break
            printf "    %-16s %6s  %s%s\n", substr(short(k), 1, 16), fd(arr[k]), bar(arr[k], total, 22), \
                (mark && (k in P) ? " " G "●" R : "")
        }
    }
    BEGIN {
        n = split(prodlist, tmp, " "); for (i = 1; i <= n; i++) P[tmp[i]] = 1
        grace *= 60; deepmin *= 60; goal = goalmin * 60
        if (color) { B = "\033[1m"; D = "\033[2m"; A = "\033[36m"; G = "\033[32m"; Y = "\033[33m"; R = "\033[0m" }
        split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", blk, " ")
    }
    mode == "week" {
        rows[++nr] = $0; next
    }
    NF >= 5 {
        s = $1; e = $2; d = e - s
        if (d <= 0) next
        active += d; cat[$3] += d; app[$5] += d
        isp = ($3 in P)
        if ($4 != "") { proj[$4] += d; if (isp) pproj[$4] += d; if ($3 == "ai") aiproj[$4] += d; if (e > seen[$4]) seen[$4] = e }
        if (isp) {
            prod += d
            if (sst == "" || s - plast > grace) { endstreak(); sst = s; sprod = 0 }
            plast = e; sprod += d
        }
        if (d >= 10) { if (prevc != "" && $5 != prevc) sw++; prevc = $5 }
        t = s
        while (t < e) {
            h = int((t - day0) / 3600); nb = day0 + (h + 1) * 3600
            piece = (e < nb ? e : nb) - t
            hr[h] += piece; if (isp) hp[h] += piece
            t += piece
        }
        if (mode == "timeline") {
            key = $3 "\t" $4 "\t" $5
            if (key == lastkey && s - lend < 60) { tl_e[ntl] = e }
            else { ntl++; tl_s[ntl] = s; tl_e[ntl] = e; tl_k[ntl] = key; tl_t[ntl] = $6 }
            lastkey = key; lend = e
        }
    }
    END {
        endstreak()
        sph = active > 0 ? sw / (active / 3600) : 0

        if (mode == "vals") {
            PROCINFO["sorted_in"] = "@val_num_desc"
            top = ""; n = 0
            for (k in pproj) { if (++n > 3) break; top = top (top == "" ? "" : ", ") k " " fd(pproj[k]) }
            printf "%d\t%d\t%d\t%d\t%.1f\t%d\t%s\n", prod, active, deep, longest, sph, deeptot, (top == "" ? "-" : top)
            exit
        }

        if (mode == "week") {
            printf "\n  %sdaytrack%s · last 7 days %s(goal %s/day)%s\n\n", B A, R, D, fd(goal), R
            for (i = 1; i <= nr; i++) {
                split(rows[i], f, "\t")
                tot += f[2]; act += f[3]; dp += f[4]
                if (f[2] > best) { best = f[2]; bestday = f[1] }
                met = goal > 0 && f[2] >= goal
                printf "  %s  %s%6s%s  %s %s  %s%5s active · %d deep%s  %s\n", f[1], B, fd(f[2]), R, \
                    bar(f[2], goal, 20), (met ? G "✓" R : " "), D, fd(f[3]), f[4], R, (f[8] == "-" ? "" : f[8])
            }
            printf "\n  Total %s%s%s productive · avg %s/day · %d deep sessions\n", B, fd(tot), R, fd(tot / 7), dp
            if (best > 0) printf "  Best day %s (%s)\n", bestday, fd(best)
            exit
        }

        if (mode == "projects") {
            printf "\n  %sdaytrack%s · projects\n\n", B A, R
            if (length(proj) == 0) { print "  No projects seen yet."; exit }
            PROCINFO["sorted_in"] = "@val_num_desc"
            for (k in proj) if (proj[k] > maxp) maxp = proj[k]
            for (k in proj)
                printf "    %-18s %6s  %s  %s%s%s\n", substr(k, 1, 18), fd(proj[k]), bar(proj[k], maxp, 20), \
                    D, (k in aiproj ? int(aiproj[k] * 100 / proj[k]) "% with AI · " : "") "last " strftime("%a %d %b", seen[k]), R
            exit
        }

        if (mode == "timeline") {
            printf "\n  %sdaytrack%s · timeline %s\n\n", B A, R, dayname
            for (i = 1; i <= ntl; i++) {
                if (tl_e[i] - tl_s[i] < 60) continue
                split(tl_k[i], k, "\t")
                c = (k[1] in P) ? A : D
                printf "  %s–%s  %6s  %s%-7s%s %-16s %s%s%s\n", strftime("%H:%M", tl_s[i]), strftime("%H:%M", tl_e[i]), \
                    fd(tl_e[i] - tl_s[i]), c, k[1], R, substr(k[2] == "" ? k[3] : k[2], 1, 16), D, substr(tl_t[i], 1, 48), R
            }
            exit
        }

        # report
        printf "\n  %sdaytrack%s · %s\n\n", B A, R, dayname
        if (active == 0) { print "  Nothing tracked yet."; exit }
        printf "  %-11s %s%6s%s  %s  %d%% of %s goal\n", "Productive", B, fd(prod), R, bar(prod, goal, 22), \
            (goal > 0 ? prod * 100 / goal : 0), fd(goal)
        printf "  %-11s %6s  %d%% of tracked time was productive\n", "Active", fd(active), prod * 100 / active
        printf "  %-11s %6s  %d session%s ≥ %s · longest streak %s\n", "Deep work", fd(deeptot), deep, \
            (deep == 1 ? "" : "s"), fd(deepmin), fd(longest)
        lbl = sph < 8 ? G "calm" R : sph < 20 ? Y "busy" R : Y "scattered" R
        printf "  %-11s %6.1f  window switches per hour · %s\n", "Focus", sph, lbl
        first = -1
        for (h = 0; h < 24; h++) if (hr[h] > 0) { if (first < 0) first = h; last = h }
        spark = ""
        for (h = first; h <= last; h++) {
            if (hp[h] > 0) { lv = int(hp[h] / 3600 * 7) + 1; spark = spark A blk[lv > 8 ? 8 : lv] R }
            else if (hr[h] > 0) spark = spark D "▁" R
            else spark = spark " "
        }
        printf "  %-11s %02d %s %02d  %s(productive per hour)%s\n", "Day", first, spark, last + 1, D, R
        section("Categories", cat, active, 10, 1)
        section("Projects", proj, active, 8, 0)
        section("Apps", app, active, 6, 0)
        print ""
    }'
}

day_vals() { data_for "$1" | analyze vals "$1"; }

# --- daemon -----------------------------------------------------------------

# Empty fields are written as "-": the shell's read collapses consecutive tabs.
write_live() {
    printf '%s\t0\t%s\t%s\t%s\t%s\n' "$cur_start" "$cur_cat" "${cur_proj:--}" "$cur_class" "${cur_title:--}" >"$run_dir/current"
}

close_seg() {
    [ -n "$cur_start" ] || return 0
    if [ "$1" -gt "$cur_start" ]; then
        title=$cur_title
        has_word "$PRIVATE_CATS" "$cur_cat" && title=
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$cur_start" "$1" "$cur_cat" "$cur_proj" "$cur_class" "$title" \
            >>"$(log_of "$(day_of "$cur_start")")"
    fi
    cur_start=
    rm -f "$run_dir/current"
}

# Start a new segment unless the focused window still belongs to the
# current one (same app, category and project; title changes alone don't
# split segments, so terminal spinners don't flood the log).
switch_to() {
    if [ -z "$2" ]; then
        close_seg "$1"
        return
    fi
    r=$(classify "$2" "$3")
    c=${r%%"$TAB"*} p=${r#*"$TAB"}
    if [ -n "$cur_start" ] && [ "$2" = "$cur_class" ] && [ "$c" = "$cur_cat" ] && [ "$p" = "$cur_proj" ]; then
        return
    fi
    close_seg "$1"
    cur_start=$1 cur_class=$2 cur_title=$3 cur_cat=$c cur_proj=$p
    case $2 in code | code-url-handler | cursor | org.wezfurlong.wezterm) remember_project "$p" ;; esac
    if [ -n "$p" ] && has_word "$PRODUCTIVE" "$c"; then last_proj=$p; fi
    write_live
}

marker_is_today() { [ "$(cat "$data_dir/.$1" 2>/dev/null)" = "$(today)" ]; }
set_marker() { today >"$data_dir/.$1"; }

recap_check() {
    [ "$RECAP" = 1 ] || return 0
    marker_is_today recap && return 0
    set_marker recap
    y=$(date -d yesterday +%F)
    [ -s "$(log_of "$y")" ] || return 0
    IFS=$TAB read -r prod active deep _ _ _ top <<EOF
$(day_vals "$y")
EOF
    [ "$active" -gt 0 ] || return 0
    pct=$((prod * 100 / (GOAL_MIN * 60)))
    notify "Yesterday: $(fmt "$prod") productive ($pct% of goal)" \
        "$(fmt "$active") active · $deep deep session(s)
Top: $top"
}

goal_check() {
    marker_is_today goal && return 0
    IFS=$TAB read -r prod _ _ _ _ _ top <<EOF
$(day_vals "$(today)")
EOF
    if [ "$prod" -ge $((GOAL_MIN * 60)) ]; then
        set_marker goal
        notify "Daily goal reached" "$(fmt "$prod") productive today. Top: $top"
        refresh_bar
    fi
}

nudges() {
    grace=$((STREAK_GRACE_MIN * 60))
    if has_word "$PRODUCTIVE" "$cur_cat"; then
        if [ -z "$streak_start" ] || [ $(($1 - last_prod)) -gt "$grace" ]; then
            streak_start=$cur_start
            next_break=$((streak_start + BREAK_AFTER_MIN * 60))
        fi
        last_prod=$1
        if [ "$BREAK_AFTER_MIN" -gt 0 ] && [ "$1" -ge "$next_break" ]; then
            notify "Time for a break" "Focused for $(fmt $(($1 - streak_start))) straight. Stand up, drink some water, rest your eyes for 5 minutes."
            next_break=$(($1 + BREAK_REPEAT_MIN * 60))
        fi
    elif [ -n "$streak_start" ] && [ $(($1 - last_prod)) -gt "$grace" ]; then
        streak_start=
    fi

    if has_word "$DISTRACT_CATS" "$cur_cat"; then
        [ -n "$fun_start" ] || fun_start=$cur_start
        if [ "$DISTRACT_AFTER_MIN" -gt 0 ] && [ -z "$fun_nudged" ] &&
            [ $(($1 - fun_start)) -ge $((DISTRACT_AFTER_MIN * 60)) ] && ! marker_is_today goal; then
            msg="$(fmt $(($1 - fun_start))) on ${cur_title:-$cur_class}."
            [ -n "$last_proj" ] && msg="$msg Back to $last_proj?"
            notify "Drifting off?" "$msg"
            fun_nudged=1
        fi
    else
        fun_start='' fun_nudged=''
    fi
}

on_tick() {
    # Split the open segment at midnight so each day's file stands alone.
    if [ -n "$cur_start" ] && [ "$(day_of "$cur_start")" != "$(day_of "$1")" ]; then
        mid=$(midnight "$(day_of "$1")")
        set -- "$1" "$cur_class" "$cur_title" "$cur_cat" "$cur_proj"
        close_seg "$mid"
        cur_start=$mid cur_class=$2 cur_title=$3 cur_cat=$4 cur_proj=$5
    fi
    recap_check

    away=
    [ -e "$run_dir/paused" ] && away=paused
    pidof hyprlock >/dev/null 2>&1 && away=locked
    [ -z "$away" ] && [ -r "$run_dir/idle" ] && away=idle

    if [ -n "$away" ]; then
        if [ -n "$cur_start" ]; then
            end=$1
            # hypridle reports idleness after its timeout; backdate to when
            # input actually stopped.
            if [ "$away" = idle ]; then
                since=$(cat "$run_dir/idle")
                [ "$since" -gt "$cur_start" ] && [ "$since" -lt "$1" ] && end=$since
            fi
            close_seg "$end"
        fi
    else
        win=$(hyprctl activewindow -j 2>/dev/null | jq -r '[.class // "", .title // ""] | @tsv' 2>/dev/null)
        switch_to "$1" "${win%%"$TAB"*}" "$(clean "${win#*"$TAB"}")"
        if [ -n "$cur_start" ]; then
            write_live
            nudges "$1"
        fi
        ticks=$((ticks + 1))
        [ $((ticks % 4)) -eq 0 ] && goal_check
    fi
    printf '%s\t%s\n' "${away:--}" "${streak_start:--}" >"$run_dir/state"
}

event_loop() {
    cur_start='' away='' streak_start='' last_prod=0 next_break=0 fun_start='' fun_nudged='' last_proj='' ticks=0
    while IFS= read -r line; do
        case $line in
        tick) on_tick "$(now)" ;;
        activewindow\>\>*)
            [ -z "$away" ] || continue
            rest=${line#activewindow>>}
            switch_to "$(now)" "${rest%%,*}" "$(clean "${rest#*,}")"
            ;;
        esac
    done
    end=$(cat "$run_dir/stopped" 2>/dev/null) || end=$(now)
    close_seg "$end"
}

daemon() {
    if daemon_alive; then
        echo "daytrack: already running" >&2
        exit 1
    fi
    sock=${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock
    if [ ! -S "$sock" ]; then
        echo "daytrack: Hyprland event socket not found" >&2
        exit 1
    fi
    echo $$ >"$run_dir/pid"
    rm -f "$run_dir/stopped"

    # A segment left open by a crash or logout ends when it was last refreshed.
    if [ -r "$run_dir/current" ]; then
        last=$(stat -c %Y "$run_dir/current")
        awk -F'\t' -v OFS='\t' -v e="$last" -v dir="$data_dir" '
            e > $1 { $2 = e; if ($4 == "-") $4 = ""; if ($6 == "-") $6 = ""
                print >> (dir "/" strftime("%Y-%m-%d", $1) ".tsv") }' "$run_dir/current"
        rm -f "$run_dir/current"
    fi

    # Stopping the reader ends the event stream; the loop then saves the open
    # segment and exits. The pipeline runs in the background so the trap
    # fires right away instead of after the pipeline finishes.
    {
        if command -v socat >/dev/null; then
            socat -u "UNIX-CONNECT:$sock" - &
        else
            nc -U "$sock" </dev/null &
        fi
        echo $! >"$run_dir/socat.pid"
        while kill -0 "$(cat "$run_dir/socat.pid")" 2>/dev/null; do
            echo tick
            sleep "$TICK"
        done
    } | event_loop &
    loop=$!
    trap 'now >"$run_dir/stopped"; kill "$(cat "$run_dir/socat.pid")" 2>/dev/null' TERM INT HUP
    wait "$loop"
    wait "$loop" 2>/dev/null
    rm -f "$run_dir/pid" "$run_dir/state" "$run_dir/socat.pid" "$run_dir/stopped"
}

# --- waybar -----------------------------------------------------------------

json_esc() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' |
        awk '{ printf "%s%s", (NR > 1 ? "\\n" : ""), $0 }'
}

waybar_out() {
    if ! daemon_alive; then
        printf '{"text":"󱎫 off","tooltip":"daytrack is not running","class":"off"}\n'
        return
    fi
    IFS=$TAB read -r prod active deep longest sph deeptot top <<EOF
$(day_vals "$(today)")
EOF
    away='' streak=''
    [ -r "$run_dir/state" ] && IFS=$TAB read -r away streak <"$run_dir/state"
    [ "$away" = - ] && away=''
    [ "$streak" = - ] && streak=''
    cat='' proj='' class='' since=''
    [ -r "$run_dir/current" ] && IFS=$TAB read -r since _ cat proj class _ <"$run_dir/current"
    [ "$proj" = - ] && proj=''
    t=$(now) goal=$((GOAL_MIN * 60))
    pct=$((goal > 0 ? prod * 100 / goal : 0))
    streak_len=0
    [ -n "$streak" ] && streak_len=$((t - streak))

    icon=󱎫 css=normal extra=
    if [ -n "$away" ]; then
        icon=󰏤 css=away
        [ "$away" = paused ] && css=paused
    elif [ "$streak_len" -ge $((DEEP_MIN * 60)) ]; then
        icon=󰈸 css=deep extra=" · $(fmt "$streak_len")"
    elif has_word "$DISTRACT_CATS" "$cat"; then
        css=fun
    fi
    [ "$pct" -ge 100 ] && [ -z "$away" ] && [ "$css" = normal ] && icon=󰓾 css=goal

    now_line="Now: idle"
    case $away in
    paused) now_line="Paused (right-click to resume)" ;;
    locked | idle) now_line="Away ($away)" ;;
    *) [ -n "$since" ] && now_line="Now: $cat${proj:+ · $proj} ($class) for $(fmt $((t - since)))" ;;
    esac
    tip="Productive $(fmt "$prod") / $(fmt "$goal") goal ($pct%)
Active $(fmt "$active") · $sph switches/h
Deep work $(fmt "$deeptot") in $deep session(s) · longest $(fmt "$longest")
$now_line"
    [ "$streak_len" -gt 0 ] && tip="$tip
Current streak $(fmt "$streak_len")"
    [ "$top" != "-" ] && tip="$tip
Top: $top"
    tip="$tip

Click: report · Middle: week · Right: pause"

    printf '{"text":"%s %s%s","tooltip":"%s","class":"%s","percentage":%d}\n' \
        "$icon" "$(fmt "$prod")" "$extra" "$(json_esc "$tip")" "$css" "$pct"
}

# JSON for the Quickshell dashboard: today's totals, top productive
# projects and what is happening right now.
dash_json() {
    IFS=$TAB read -r prod active deep longest sph deeptot _ <<EOF
$(day_vals "$(today)")
EOF
    away='' streak=''
    [ -r "$run_dir/state" ] && IFS=$TAB read -r away streak <"$run_dir/state"
    [ "$away" = - ] && away=''
    [ "$streak" = - ] && streak=''
    cat='' proj=''
    [ -r "$run_dir/current" ] && IFS=$TAB read -r _ _ cat proj _ _ <"$run_dir/current"
    [ "$proj" = - ] && proj=''
    daemon_alive || away=off
    streak_len=0
    [ -n "$streak" ] && streak_len=$(($(now) - streak))
    top=$(data_for "$(today)" | awk -F'\t' -v prodlist="$PRODUCTIVE" '
        BEGIN { n = split(prodlist, t, " "); for (i = 1; i <= n; i++) P[t[i]] = 1 }
        ($3 in P) && $4 != "" && $2 > $1 { p[$4] += $2 - $1 }
        END {
            PROCINFO["sorted_in"] = "@val_num_desc"
            for (k in p) { if (++c > 3) break; printf "%s{\"name\":\"%s\",\"secs\":%d}", (c > 1 ? "," : ""), k, p[k] }
        }')
    # Productive seconds for the last 7 days, oldest first, ending today.
    week='' i=6
    while [ "$i" -gt 0 ]; do
        d=$(date -d "-$i day" +%F)
        week="$week{\"day\":\"$(date -d "$d" +%a)\",\"secs\":$(day_vals "$d" | cut -f1)},"
        i=$((i - 1))
    done
    week="$week{\"day\":\"$(date +%a)\",\"secs\":$prod}"
    jq -cn --argjson prod "$prod" --argjson active "$active" --argjson goal $((GOAL_MIN * 60)) \
        --argjson deep "$deep" --argjson deeptot "$deeptot" --argjson longest "$longest" \
        --argjson sph "$sph" --argjson streak "$streak_len" --argjson deepmin $((DEEP_MIN * 60)) \
        --arg away "$away" --arg cat "$cat" --arg proj "$proj" --argjson top "[$top]" --argjson week "[$week]" \
        '{prod: $prod, active: $active, goal: $goal, deep: $deep, deeptot: $deeptot, longest: $longest,
          switches: $sph, streak: $streak, deepmin: $deepmin, away: $away, cat: $cat, proj: $proj, top: $top,
          week: $week}'
}

# --- commands ---------------------------------------------------------------

week() {
    i=6
    while [ "$i" -ge 0 ]; do
        d=$(date -d "-$i day" +%F)
        printf '%s\t%s\n' "$(date -d "$d" '+%a %d')" "$(day_vals "$d")"
        i=$((i - 1))
    done | analyze week
    # Consecutive days meeting the goal; today counts once it's met.
    streak=0 i=0
    while [ "$i" -lt 60 ]; do
        prod=$(day_vals "$(date -d "-$i day" +%F)" | cut -f1)
        if [ "$prod" -ge $((GOAL_MIN * 60)) ]; then
            streak=$((streak + 1))
        elif [ "$i" -gt 0 ]; then
            break
        fi
        i=$((i + 1))
    done
    [ "$streak" -gt 0 ] && printf '  Goal streak: %d day(s) in a row\n' "$streak"
    echo
}

projects() {
    n=${1:-30} i=0
    while [ "$i" -lt "$n" ]; do
        data_for "$(date -d "-$i day" +%F)"
        i=$((i + 1))
    done | analyze projects
    printf '  (last %s days)\n\n' "$n"
}

resolve_day() {
    case ${1:-today} in
    today) today ;;
    yesterday) date -d yesterday +%F ;;
    *) date -d "$1" +%F ;;
    esac
}

usage() {
    cat <<'EOF'
daytrack: automatic time tracking from Hyprland window focus

  today [DAY]       report for today (or yesterday, 2026-10-15, "3 days ago")
  timeline [DAY]    every focus block of the day, in order
  week              last 7 days, goal streak
  projects [DAYS]   time per project over the last DAYS days (default 30)
  pause | resume | toggle
                    stop tracking for a while (privacy mode)
  open              report in a floating terminal (Super+I)
  daemon            the tracker itself (started from Hyprland autostart)
  stop              stop the tracker, saving the current block
  idle SECS | active
                    called by hypridle
  waybar            JSON for the Waybar module
  dash              JSON for the Quickshell dashboard

Data: ~/.local/share/daytrack/   Config: ~/.config/daytrack/
EOF
}

cmd=${1:-today}
[ $# -gt 0 ] && shift
case $cmd in
daemon) daemon ;;
stop)
    daemon_alive || exit 0
    kill "$(cat "$run_dir/pid")"
    # Wait for the loop to save the open segment (it notices within one tick).
    i=0
    while daemon_alive && [ "$i" -lt $((TICK + 5)) ]; do
        sleep 1
        i=$((i + 1))
    done
    ;;
today | report) d=$(resolve_day "$1") && data_for "$d" | analyze report "$d" ;;
timeline | log) d=$(resolve_day "$1") && data_for "$d" | analyze timeline "$d" ;;
week) week ;;
projects) projects "$1" ;;
waybar) waybar_out ;;
dash) dash_json ;;
idle) echo $(($(now) - ${1:-0})) >"$run_dir/idle" ;;
active) rm -f "$run_dir/idle" ;;
pause)
    touch "$run_dir/paused"
    notify "daytrack paused" "Nothing is recorded until you resume."
    refresh_bar
    ;;
resume)
    rm -f "$run_dir/paused"
    notify "daytrack resumed" ""
    refresh_bar
    ;;
toggle) if [ -e "$run_dir/paused" ]; then "$0" resume; else "$0" pause; fi ;;
open)
    # shellcheck disable=SC2016 # expanded by the inner sh
    wezterm start --class daytrack -- sh -c '"$0" today; "$0" week; printf "  Press Enter to close"; read -r _' "$0" \
        >/dev/null 2>&1 &
    ;;
help | -h | --help) usage ;;
*)
    usage >&2
    exit 1
    ;;
esac
