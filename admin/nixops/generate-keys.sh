#!/usr/bin/env bash
set -euo pipefail
set -x
host=$1; shift
regenerate=${2:-false}
sops_file=${3:-hosts/$host/secrets/secrets.yaml}

command -v sops

d=$(mktemp -d)
trap "rm -r $d" EXIT
keyfile=$d/key

declare -a keys
keys+=(wireguard_key)
keys+=(ssh_host_rsa_key)
keys+=(ssh_host_rsa_key.pub) # order matter (private key before pub one)
keys+=(ssh_host_rsa_key-cert.pub)
keys+=(ssh_host_ed25519_key)
keys+=(ssh_host_ed25519_key.pub) # order matter (private key before pub one)
keys+=(ssh_host_ed25519_key-cert.pub)
keys+=(missing_key)

for key in ${@:-${keys[@]}}; do
    echo "key ${key}"
    # test if key is present
    if [[ "$(nix eval .\#nixosConfigurations.$host.config.sops.secrets --json | jq -r '.["'$key'"]')" == "null" ]]; then
        echo "missing key: $key"
        if grep -q "$key:" $sops_file; then
            echo "but found in $sops_file"
        fi
    else
        # check if the key exists
        if ! sops  --extract '["'$key'"]' -d $sops_file > $keyfile; then
            regenerate=true
        fi
        if $regenerate; then
            case "$key" in
                wireguard_key)
                    wg genkey > $keyfile
                    cat $keyfile | wg pubkey | tee hosts/$host/wg_key.pub
                    ;;
                ssh_host_rsa_key)
                    ssh $host "sudo cat /persist/etc/ssh/ssh_host_rsa_key" > $keyfile
                    #ssh-keygen -t $type $options -f $f -N "" -C ""
                    ;;
                ssh_host_rsa_key.pub)
                    ssh-keygen -y -f <(sops --extract '["ssh_host_rsa_key"]' -d $sops_file) > $keyfile
                    ;;
                ssh_host_ed25519_key)
                    ssh-keygen -t ed25519 $options -f $keyfile -N "" -C ""
                    ;;
                ssh_host_ed25519_key.pub)
                    ssh-keygen -y -f <(sops --extract '["ssh_host_ed25519_key"]' -d $sops_file) > $keyfile
                    ;;
                ssh_host_rsa_key-cert.pub|\
                ssh_host_ed25519_key-cert.pub)
                    pass show ssh-ca/home > $d/ssh-ca
                    chmod 600 $d/ssh-ca

                    ssh-keygen -s $d/ssh-ca \
                        -P "$(pass show ${ca}-pass)" \
                        -I "$host host key" \
                        -n "$realms" \
                        -V -5m:+$(( 365 * 1))d \
                        -h \
                        $keyfile
                    ;;
                *)
                    echo "ERROR: unknown key '$key'"
                    exit 1
            esac
            # put the key value in the SOPS file
            sops --set '["'$key'"] "'"$(cat $keyfile)"'"' $sops_file
        fi
    fi
done

exit
