#!/usr/bin/env bash

freqfiles=(/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq)
sleeptime="${1:-0.010}"

while true; do
    read -t "$sleeptime" #10 ms sleep, w/o fork();exec();
    for f in "${freqfiles[@]}"; do
        read <$f
    done
done


