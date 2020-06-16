#!/usr/bin/env bash
# nixpkgs#bup nixpkgs#par2cmdline nixpkgs#fpart

set -xeu -o pipefail
command -v bup
command -v par2
command -v fpart

file_list=$1
shift
file_list=$(readlink -f $file_list)

bluray_id=22
#uuidgen
declare -A uuids
uuids[18]=c5dcd424-09d3-44b1-aaa0-17eb0ad827f6
uuids[19]=2c1c66ff-7d5f-4787-8799-3503240d75f5
uuids[20]=d5066f45-7514-484a-94a0-a46d753d4f09
uuids[21]=cd6c7c3e-d994-459a-a6e9-198a9737f597
uuids[22]=44995e74-effb-4a78-9278-d717ca213fb7
uuid=${uuids[$bluray_id]}

bd_size=$((12219392*2-128*1024))

#sudo zfs create -o mount=legacy -o quota=25G icybox1/bd_22

#if ! test -e bd_${bluray_id}.img; then
#    truncate -s ${bd_size}KB bd_${bluray_id}.img
#
#    mkfs.ext4 -L bd_${bluray_id} bd_${bluray_id}.img
#
    sudo mkdir -p /media/bd_${bluray_id}
#    sudo mount -o loop,rw bd_${bluray_id}.img /media/bd_${bluray_id} || true
#
#    sudo mount -t zfs icybox1/bd_22 /media/bd_${bluray_id}
#    sudo chown dguibert:dguibert /media/bd_${bluray_id}
	for repo in archives Documents Music work Videos; do
        (
        cd ~/$repo
        git annex enableremote bd_${bluray_id} type=bup encryption=none buprepo=/media/bd_${bluray_id} || \
            git annex initremote bd_${bluray_id} uuid=$uuid type=bup encryption=none buprepo=/media/bd_${bluray_id}
        git annex fsck --from bd_${bluray_id} || true
        )
    done
#else
##
##if ! test -e bd_${bluray_id}.udf; then
##    truncate -s ${bd_size}KB bd_${bluray_id}.udf
##    #--lvid=            Logical Volume Identifier (default: LinuxUDF)
##    #--vid=             Volume Identifier (default: LinuxUDF)
##    #--vsid=            17.-127. character of Volume Set Identifier (default: LinuxUDF)
##    #--fsid=            File Set Identifier (default: LinuxUDF)
##    mkudffs --media-type=dvdram --spartable=2  --lvid="BD_${bluray_id}" --vid="BD_${bluray_id}" --vsid="BD_${bluray_id}" --fsid="BD_${bluray_id}"   bd_${bluray_id}.udf
##
##    sudo mkdir -p /media/bd_${bluray_id}
##    sudo mount -t udf -o loop,rw bd_${bluray_id}.udf /media/bd_${bluray_id} || true
##
##    sudo chown dguibert:dguibert /media/bd_${bluray_id}
##    for repo in Videos archives work Documents Music; do
##        (
##        cd ~/$repo
##        git annex enableremote bd_${bluray_id} type=bup encryption=none buprepo=/media/bd_${bluray_id} || \
##            git annex initremote bd_${bluray_id} uuid=$uuid type=bup encryption=none buprepo=/media/bd_${bluray_id}
##        git annex fsck --from bd_${bluray_id} || true
##        )
##    done
##else
##
#    sudo mkdir -p /media/bd_${bluray_id}
#    sudo mount -t zfs icybox1/bd_22 /media/bd_${bluray_id}
##    sudo mount -o loop,rw bd_${bluray_id}.udf /media/bd_${bluray_id} || true
#    sudo chown dguibert:dguibert /media/bd_${bluray_id}
##
##fi

#for repo in archives Documents Music work Videos; do
for repo in archives ; do
  (
    cd $repo
    grep $repo $file_list | cut -d " " -f 2- | tr "\n" "\0" \
      | git annex copy --to bd_${bluray_id} --batch -z $@
  )
done
#while IFS= read -r line; do
#  repo=$(echo "$line" | sed -e 's:\([^/]\+\)/.*:\1:')
#  file=$(echo "$line" | sed -e "s:[^/]\+/::")
#  #echo "$repo => $file"
#  (cd $repo; git annex copy --to bd_${bluray_id} "$file")
#done < $file_list

(cd /media/bd_${bluray_id} ; bup fsck -v -g objects/pack/*.pack)
