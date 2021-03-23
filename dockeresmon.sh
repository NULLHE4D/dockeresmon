#!/bin/bash

set -e
set -o pipefail

function script_echo() {
    echo "[dockeresmon] $(date) $1"
}

function inc_file_num() {
    target_file="$1"
    if [ -f "$target_file" ]; then
        new_num=$(($(cat "$target_file") + 1))
    else
        new_num="1"
    fi
    echo "$new_num" > $target_file
}

while getopts "c:" opt; do
    case $opt in
        c) config_file="$OPTARG" ;;
    esac
done

if [ -z "$config_file" ]; then
    >&2 echo "usage: dockeresmon.sh -c [CONFIG_FILE]"
    exit 1
fi

tmp_dir="/tmp/dockeresmon"
mkdir -p $tmp_dir

stats=$(docker stats --no-stream)

jq -c ".[]" $config_file | while read item; do

    container=$(echo $item | jq -r ".container")
    cpu_threshold=$(echo $item | jq -r ".cpu_threshold")
    cpu_cmd=$(echo $item | jq -r ".cpu_command")
    cpu_intervals=$(echo $item | jq -r ".cpu_intervals")
    memory_threshold=$(echo $item | jq -r ".memory_threshold")
    memory_cmd=$(echo $item | jq -r ".memory_command")
    memory_intervals=$(echo $item | jq -r ".memory_intervals")

    # '|| true' is to avoid exiting the script when grep doesn't find any match
    line=$(echo "$stats" | grep "$container" || true)

    if [ -z "$line" ] || [ $(echo "$line" | awk '{print $2}') != "$container" ]; then
        script_echo "container '$container' isn't running. skipping.."
        continue
    fi

    if [ -n "$cpu_threshold" ] && [ -n "$cpu_cmd" ] && [ -n "$cpu_intervals" ]; then
    
        cpu_percentage=$(echo "$line" | awk '{print $3}' | sed 's/%//')
        cpu_file="${tmp_dir}/${container}.cpu"

        if (( $(echo "$cpu_percentage >= $cpu_threshold" | bc -l) )); then
            inc_file_num "$cpu_file"
            script_echo "container '$container' passed CPU threshold ($(cat $cpu_file))"
    
            for i in ${cpu_intervals//,/ }; do
                if (( $(echo "$(cat $cpu_file) == $i" | bc -l) )); then
                    $(eval "$cpu_cmd")
                    break
                fi
            done
        else
            echo "0" > $cpu_file
        fi

    fi

    if [ -n "$memory_threshold" ] && [ -n "$memory_cmd" ] && [ -n "$memory_intervals" ]; then

        memory_percentage=$(echo "$line" | awk '{print $7}' | sed 's/%//')
        memory_file="${tmp_dir}/${container}.mem"

        if (( $(echo "$memory_percentage >= $memory_threshold" | bc -l) )); then
            inc_file_num "$memory_file"
            script_echo "container '$container' passed memory threshold ($(cat $memory_file))"
    
            for i in ${memory_intervals//,/ }; do
                if (( $(echo "$(cat $memory_file) == $i" | bc -l) )); then
                    $(eval "$memory_cmd")
                    break
                fi
            done
        else
            echo "0" > $memory_file
        fi

    fi

done
