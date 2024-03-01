#!/usr/bin/env bash

## https://unix.stackexchange.com/questions/57940/trap-int-term-exit-really-necessary
set -eu
cleanup() {
    echo "cleanup ($1)"
    trap - INT TERM EXIT  # avoid reexecuting handlers
    if [ "$1" = 130 ]; then
        kill -INT $$
    elif [ "$1" = 143 ]; then
        kill -TERM $$
    else
        exit "$1"
    fi
}
trap 'cleanup 130' INT
trap 'cleanup 143' TERM
trap 'cleanup $?' EXIT

if [ "${1-}" = fail ]; then
    no-such-command
fi
sleep 3
