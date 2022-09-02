#!/bin/bash
set -eu

# Pretty sure this is the most accurate & complete measurement of CPU
# frequency I can make.

get_mhz_limits () {
    #output:
    # 800
    # 4200
    for f in /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_{min,max}_freq; do
        if [ -e "$f" ]; then
            dc -e "$(cat $f) 1000 / p"
        else
            exit 2
        fi
    done
}

runbpf () {
    # $1 = ncpus
    # $2 = delay_ms
    # $3 = minimum_mhz
    # $4 = maximum_mhz
    # $5 = hist_bin_size_mhz
    bpftrace "$(dirname "$0")/omnibus_cpufreq_compatible.bt" "$@"
}

start_background_cpufreq_reader () {
    exec {blocked_fd}<> <(:) # file descriptor will always block on read
    (
        cur_freqs=(/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq)
        while true; do
            # sleep without subprocess
            # Any period less than 10ms is rate limited by the kernel
            read -t 0.010 -u $blocked_fd || true 
            for file in "${cur_freqs[@]}"; do
                read <$file
            done
        done
    ) &
    trap "kill $!" EXIT
}

usage () {
    echo "Usage: sudo $(basename "$0") -d SECONDS"
    exit 1
}

main () {
    if [[ $# -eq 2 && "$1" == "-d" ]]; then
        local ncpu delay_ms
        ncpu="$(grep -c proc /proc/cpuinfo)"
        delay_ms="$(bc <<<"$2 * 1000 / 1")"
        start_background_cpufreq_reader
        runbpf "$ncpu" "$delay_ms" $(get_mhz_limits) 200
    else
        usage
    fi
}

main "$@"
