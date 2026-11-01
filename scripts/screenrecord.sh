#!/bin/sh
# Screen recording backend for ArchEclipse's ScreenRecorder service.
#   screenrecord.sh start --monitor NAME          record a whole monitor
#   screenrecord.sh start --area --monitor NAME   record an area picked with slurp
#   screenrecord.sh stop                          stop and save the recording
# Recordings go to ~/Videos/Recordings. The monitor being recorded is written
# to $XDG_RUNTIME_DIR/screenrecord_monitor, which the bar reads to know where
# to show the recording pill.

set -eu

state="${XDG_RUNTIME_DIR:-/tmp}"
monitor_file="$state/screenrecord_monitor"
pid_file="$state/screenrecord.pid"
output_file="$state/screenrecord.output"
log_file="$state/screenrecord.log"
out_dir="$HOME/Videos/Recordings"

recorder_pid() {
    if [ -s "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        cat "$pid_file"
    else
        pgrep -f '(^|/)gpu-screen-recorder([[:space:]]|$)' | head -n1
    fi
}

start() {
    area=0
    monitor=""
    while [ $# -gt 0 ]; do
        case "$1" in
        --area) area=1 ;;
        --monitor)
            monitor="${2:-}"
            shift
            ;;
        *)
            echo "screenrecord.sh: unsupported option $1" >&2
            exit 2
            ;;
        esac
        shift
    done

    if [ -n "$(recorder_pid)" ]; then
        echo "A recording is already running." >&2
        exit 1
    fi
    if [ -z "$monitor" ]; then
        monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
    fi

    mkdir -p "$out_dir"
    file="$out_dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"

    if [ "$area" -eq 1 ]; then
        # Cancelling slurp exits non-zero with no output, which the bar
        # treats as a silent no-op.
        region="$(slurp -f '%wx%h+%x+%y' 2>/dev/null)" || exit 1
        set -- -w region -region "$region"
    else
        set -- -w "$monitor"
    fi

    printf '%s\n' "$monitor" >"$monitor_file"
    printf '%s\n' "$file" >"$output_file"
    setsid -f gpu-screen-recorder "$@" -f 60 -a default_output -o "$file" >"$log_file" 2>&1
    # setsid -f returns before the recorder is up, so look for it and report
    # an early failure (bad monitor name, no encoder) back to the bar.
    sleep 1
    pid="$(pgrep -n -f '(^|/)gpu-screen-recorder([[:space:]]|$)' || true)"
    if [ -z "$pid" ]; then
        rm -f "$monitor_file" "$output_file"
        tail -n 5 "$log_file" >&2
        exit 1
    fi
    printf '%s\n' "$pid" >"$pid_file"
}

stop() {
    pid="$(recorder_pid)"
    if [ -z "$pid" ]; then
        echo "No recording is running." >&2
        exit 1
    fi
    # SIGINT makes gpu-screen-recorder finish writing the file before exiting.
    kill -INT "$pid"
    tries=0
    while kill -0 "$pid" 2>/dev/null && [ "$tries" -lt 50 ]; do
        sleep 0.2
        tries=$((tries + 1))
    done
    file="$(cat "$output_file" 2>/dev/null || true)"
    rm -f "$monitor_file" "$pid_file" "$output_file"
    if [ -n "$file" ] && [ -f "$file" ]; then
        notify-send "Recording saved" "$file"
    fi
}

case "${1:-}" in
start)
    shift
    start "$@"
    ;;
stop) stop ;;
*)
    echo "usage: screenrecord.sh start [--area] [--monitor NAME] | stop" >&2
    exit 2
    ;;
esac
