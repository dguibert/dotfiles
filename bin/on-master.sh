#!/bin/sh

set -vuxe

export LOCKFILE_DIR=${LOCKFILE_DIR:-$PWD}
export TIMEOUT=2 #minutes
export TIMEOUT_MASTER=3 #minutes

eexit() {
    local error_str="$@"

    echo $error_str 1>&2
    exit 1
}


# Call getopt to validate the provided input.
options=$(getopt -o l:d: --long lockfile:lockdir: -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided" 1>&2
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
    --)
        shift
        break
        ;;
    esac
    shift
done

# DEBUG
#set -xv
# default values if not defined by command line options
lockdir=${lockdir:-$LOCKFILE_DIR}
lockfile=${lockfile:-$lockdir/on-master.lock}

(
	flock -w $(( $TIMEOUT*60 )) 200 || eexit "master: $(hostname) could not acquire master rights to launch '$@'"

	echo "$0: $(hostname) ready to launch '$@'" 1>&2
	DATE0=$(date +%Y%m%d%H%M%S)
	eval "$@"
	DATE1=$(date +%Y%m%d%H%M%S)
	echo "$0: $(hostname) has launched '$@' in $(( $DATE1-$DATE0 ))s" 1>&2

	SLEEP_TIMEOUT=$(( $TIMEOUT_MASTER*60-($DATE1-$DATE0) ))
	if [ "$SLEEP_TIMEOUT" -gt "0" ]; then
		sleep $SLEEP_TIMEOUT
	fi

) 200> $lockfile
rm -f $lockfile

