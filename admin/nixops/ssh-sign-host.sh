#!/usr/bin/env bash
set -efuo pipefail
set -x
echo $0 $@ >&2
sops_file=$1
ca=$2
realms=$3
type=$4

hostname=$(basename $(dirname $(dirname $sops_file)))

options=""
# ssh rpi41 "sudo cat /persist/etc/ssh/ssh_host_rsa_key"
test $type == "rsa" && options+=" -b 4096"

command -v pass
command -v sops

if ! pass show "$ca" >/dev/null; then
  echo "run $ @ssh_generate_ca@ $ca"
  exit -1
  if ! pass show "${ca}-pass" >/dev/null; then
    echo "run $ @ssh_generate_ca@ $ca"
    exit -2
  fi
fi

key_name='["ssh_host_'${type}'_key"]'
pub_name='["ssh_host_'${type}'_key.pub"]'
cert_name='["ssh_host_'${type}'_key-cert.pub"]'

d=$(mktemp -d)
f=$d/host_key
pubfile=$d/host_key-cert.pub
trap "rm -r $d" EXIT

# sops --extract '["ssh_host_rsa_key"]' -d hosts/rpi41/secrets/secrets.yaml
if ! sops  --extract $cert_name -d $sops_file > $pubfile; then
  rm $pubfile
  if ! sops --extract $key_name -d $sops_file > $f; then
    rm $f
    # ssh-key does not exist; create it
    # ssh rpi41 "sudo cat /persist/etc/ssh/ssh_host_rsa_key"
    # get the private key or generate it
    if test $type == "rsa"; then
      ssh $hostname "sudo cat /persist/etc/ssh/ssh_host_${type}_key" > $f
    else
      ssh-keygen -t $type $options -f $f -N "" -C ""
    fi

    # sops ~/git/svc/sops/example.yaml --set '["an_array"][1]' '"secretuser2"'
    sops --set '["ssh_host_'${type}'_key"] "'"$(cat $f)"'"' $sops_file
  fi
  if ! sops --extract ${pub_name} -d $sops_file > $f.pub; then
    ssh-keygen -y -f <(sops --extract $key_name -d $sops_file) -C $hostname > $f.pub
    sops --set '["ssh_host_'${type}'_key.pub"] "'"$(cat $f.pub)"'"' $sops_file
  fi
  pass show ${ca} > $d/ssh-ca
  chmod 600 $d/ssh-ca

  ssh-keygen -s $d/ssh-ca \
    -P "$(pass show ${ca}-pass)" \
    -I "$hostname host key" \
    -n "$realms" \
    -V -5m:+$(( 365 * 1))d \
    -h \
    $f.pub
  sops --set '["ssh_host_'${type}'_key-cert.pub"] "'"$(cat $pubfile)"'"' $sops_file
else
  sops --extract ${key_name} -d $sops_file
  sops --extract ${pub_name} -d $sops_file
fi
cat $pubfile >&2

