#!/usr/bin/env bash
set -euo pipefail
set -x
host=$1; shift
regenerate=false
host_sops_file=hosts/$host/secrets/secrets.yaml

command -v sops

d=$(mktemp -d)
trap "rm -r $d" EXIT
keyfile=$d/key

options=""

declare -a keys
#keys+=(wireguard_key)
#keys+=(ssh_host_rsa_key)
#keys+=(ssh_host_rsa_key.pub) # order matter (private key before pub one)
#keys+=(ssh_host_rsa_key-cert.pub)
#keys+=(ssh_host_ed25519_key)
#keys+=(ssh_host_ed25519_key.pub) # order matter (private key before pub one)
#keys+=(ssh_host_ed25519_key-cert.pub)
#keys+=(missing_key)
declare -A realms
realms[titan]="titan,192.168.1.24,10.147.27.24"

# Call getopt to validate the provided input.
options=$(getopt -o rkf: --long key:,file: -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    -r)
        regenerate=true
        ;;
    -f|--file)
        shift; # The arg is next in position args
        host_sops_file=$1
        ;;
    -k|--key)
        shift; # The arg is next in position args
        if ! ${key_supplied:-true}; then
            keys=()
            key_supplied=true
        fi
        keys+=($1)
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

if ! ${key_supplied:-true}; then
    keys=($(nix eval .\#nixosConfigurations.$host.config.sops.secrets --json | jq -r '.[].key') )
fi

for key in ${@:-${keys[@]}}; do
    echo "key ${key}"
    # test if key is present
    if [[ "$(nix eval .\#nixosConfigurations.$host.config.sops.secrets --json | jq -r '.["'$key'"]')" == "null" ]]; then
        echo "missing key: $key"
        if grep -q "$key:" $sops_file; then
            echo "but found in $sops_file"
        fi
    else
        case "$(nix eval .\#nixosConfigurations.$host.config.sops.secrets --json | jq -r '.["'$key'"].sopsFile')" in
            *-defaults.yaml)
                sops_file=./secrets/defaults.yaml
                ;;
            *)
                sops_file=$host_sops_file
                ;;
        esac
        # check if the key exists
        if ! sops  --extract '["'$key'"]' -d $sops_file > $keyfile; then
            regenerate_=true
        fi
        case "$key" in
            *)
                regenerate_=$regenerate
        esac
        if $regenerate_; then
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
                    ca=ssh-ca/home
                    realms_=${realms[$host]}

                    case "$key" in
                        ssh_host_rsa_key-cert.pub)
                            ssh-keygen -y -f <(sops --extract '["ssh_host_rsa_key"]' -d $sops_file) > $d/priv_key;;
                        ssh_host_ed25519_key-cert.pub)
                            ssh-keygen -y -f <(sops --extract '["ssh_host_ed25519_key"]' -d $sops_file) > $d/priv_key;;
                        *)
                            echo "ERROR: unknown key '$key'"
                            exit 11
                    esac
                    ssh-keygen -s $d/ssh-ca \
                        -P "$(pass show ${ca}-pass)" \
                        -I "$host host key" \
                        -n "$realms_" \
                        -V -5m:+$(( 365 * 1))d \
                        -h \
                        $d/priv_key
                    mv $d/priv_key-cert.pub $keyfile
                    ssh-keygen -L -f $keyfile
                    ;;
                id_buildfarm)
                    rm -f $keyfile
                    ssh-keygen -t ed25519 $options -f $keyfile -N "" -C ""
                    ssh-keygen -y -f $keyfile # generate pub
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
