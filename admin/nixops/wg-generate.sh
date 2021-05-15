#!/usr/bin/env bash
set -euo pipefail
set -x
host=$1
regenerate=${2:-false}

sops_file=hosts/$host/secrets/secrets.yaml

d=$(mktemp -d)
trap "rm -r $d" EXIT
keyfile=$d/key

if ! sops  --extract '["wireguard_key"]' -d $sops_file > $keyfile; then
    regenerate=true
fi
if $regenerate; then
    wg genkey > $keyfile
    sops --set '["wireguard_key"] "'"$(cat $keyfile)"'"' $sops_file
fi

cat $keyfile | wg pubkey | tee hosts/$host/wg_key.pub
