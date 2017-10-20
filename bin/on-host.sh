#!/bin/sh

set -vuxe

eexit() {
    local error_str="$@"

    echo $error_str
    exit 1
}

export LOCKFILE_DIR=${LOCKFILE_DIR:-$HOME/logs}
export TIMEOUT=2 #minutes
export TIMEOUT_MASTER=3 #minutes
active_host=$(hostname)

# Call getopt to validate the provided input.
options=$(getopt -o l:d:h: --long lockfile:lockdir:host: -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    -l|--lockfile)
        shift; # The arg is next in position args
	lockfile=$1
        ;;
    -d|--lockdir)
        shift; # The arg is next in position args
	lockdir=$1
        ;;
    -h|--host)
        shift; # The arg is next in position args
	active_host=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

# DEBUG
set -xv
# default values if not defined by command line options
lockdir=${lockdir:-$LOCKFILE_DIR}
lockfile=${lockfile:-$lockdir/on-master.lock}

host_name=$(hostname)
if [ "$host_name" == "$active_host" ]; then
	echo "$0: $host_name is the active host" 1>&2
	echo "$0: $host_name ready to launch '$@'" 1>&2
	eval "$@"
else
	echo "$0: $host_name is not the active host" 1>&2
	echo "$0: $host_name will not launch '$@'" 1>&2
fi
