#!/usr/bin/env bash
echo "pwd: `pwd`"
echo "\$0: $0"
echo "basename: `basename $0`"
echo "dirname: `dirname $0`"
echo "dirname/readlink: $(dirname $(readlink -f $0))"
echo "bash_source: $BASH_SOURCE"
echo "$(dirname $BASH_SOURCE)"
echo "$(readlink "$(dirname $BASH_SOURCE)/..")"
