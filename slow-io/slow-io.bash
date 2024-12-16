#!/usr/bin/env bash

usage () {
    cat 1>&2 <<EOF
Usage:
  $0 <read|open> [threshold_microseconds] [bpftrace filter expression]
EOF
}

main () {
    local scriptdir="$(dirname "$0")"
    local bt_script
    case "$1" in
        read )
            bt_script="$scriptdir/slow-file-read-2.bt"
            ;;
        open )
            bt_script="$scriptdir/slow-file-open.bt"
            ;;
        * )
            usage
            exit 1
    esac
    shift
    launch_trace_script "$bt_script" "$@"
}

launch_trace_script () {
    local script="$1"
    local latency_threshold="$2"
    local filter="${3:-1}" # always true if not provided
    local tmpfile=$(mktemp)
    echo "#define FILTER ($filter)" >"$tmpfile"
    bpftrace --include "$tmpfile" "$script" "$latency_threshold"
    rm "$tmpfile"
}

main "$@"
