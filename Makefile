is_feature = $(if $(filter $1,$(.FEATURES)),T)
ifneq ($(call is_feature,oneshell),T)
	$(error This Makefile only works with a Make program that supports "oneshell" feature (version>=3.82))
endif

.ONESHELL:
.POSIX:
#.SHELLFLAGS=-x -c
HOSTNAME?=$(shell hostname -s)

all:

.PHONY:nix
nix:
	export ENVRC=nix
	export NIX_PATH=nixpkgs=$$HOME/code/nixpkgs
	proot-x86_64 -b ~/pkgs/nix-mnt:/nix bash

bup-save:
	export ANNEX_DIR=/backupwd/annex
	export BUP_DIR=$$ANNEX_DIR/bup
	test ! -d $$BUP_DIR && bup init
	bup index \
		--exclude=$(HOME)/.git \
		--exclude=$(HOME)/annex/.git/annex \
		--exclude=$$BUP_DIR \
		$(HOME)
	bup save -n home-$$(hostname) $(HOME)

	#Defend your backups from death rays (OK fine, more likely from the occasional bad disk block). This writes parity information (currently via par2) for all of the existing data so that bup may be able to recover from some amount of repository corruption:

	bup fsck -g

	cd $$ANNEX_DIR
	git annex add $$BUP_DIR/objects/pack
	git annex proxy -- git add $${BUP_DIR##$(HOME)/annex/}
	git annex proxy -- git add bup
	git annex proxy -- git commit -m "Backup on $$(date)"
	git annex sync --content

init-dotfiles-%:
	set -x
	cluster=$*
	ssh-copy-id -i ~/.ssh/id_rsa.pub $$cluster
	ssh $$cluster mkdir -p bin
	scp ~/bin/mgit $$cluster:
	ssh -vvvv $$cluster ./mgit clone ssh://dguibert@localhost:33322/home/dguibert/public_git/dotfiles.git
	rsync -aP .vim/ $$cluster:.vim/ --exclude view

init-nix-%:
	set -x
	cluster=$*
	#curl -C - -O https://nixos.org/releases/nix/nix-2.0.4/nix-2.0.4-x86_64-linux.tar.bz2
	rsync -aP nix-2.0.4-x86_64-linux.tar.bz2 $$cluster:
	ssh $$cluster "(mkdir -p ~/pkgs/nix-mnt; cd ~/pkgs/nix-mnt; tar xv --strip-components=1 -f ~/nix-2.0.4-x86_64-linux.tar.bz2; proot-x86_64 -b ~/pkgs/nix-mnt:/nix ./install)"

update-%:
	cd ~/admin/nixops
	source .envrc
	nixops deploy -I nixpkgs=$$HOME/code/nixpkgs --option allow-unsafe-native-code-during-evaluation true --include $*
	#nixops deploy -I nixpkgs=$$HOME/code/nixpkgs --option extra-builtins-file ~/admin/nixops/extra-builtins.nix --include $$HOSTNAME
update-host: update-$(HOSTNAME)
	$(shell echo $(HOSTNAME))

update-hosts:
	cd ~/admin/nixops
	source .envrc
	nixops deploy -I nixpkgs=$$HOME/code/nixpkgs --option allow-unsafe-native-code-during-evaluation true --include $$HOSTNAME
	#nixops deploy -I nixpkgs=$$HOME/code/nixpkgs -option extra-builtins-file ~/admin/nixops/extra-builtins.nix
update-packages:
	nix-env -f $$HOME/.config/nixpkgs/my-packages.nix -ir -I nixpkgs=$$HOME/code/nixpkgs/ --show-trace
	nix-env -if https://github.com/cachix/cachix/tarball/master --substituters https://cachix.cachix.org --trusted-public-keys cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM=
# nix-copy-closure -v --to manny $(nix-build --arg expr "(import <nixpkgs> {}).nix" --keep-going -Q ./maintainers/scripts/all-sources.nix -I nixpkgs=$HOME/code/nixpkgs)
update-packages-%:
	set -x
	cluster=$*
	rm -f pkgs/$$cluster*
	nix build -o pkgs/$$cluster -f $$HOME/.config/nixpkgs/my-packages@cluster.nix
	packages=$$(readlink pkgs/$$cluster*)
	nix copy -v --to ssh://$$cluster $$packages
	ssh $$cluster nix-env -i $$packages
shell-nix-scratch-gpfs:
	export PATH=/scratch_gpfs/bguibertd/nix/var/nix/profiles/default/bin:$$PATH
	export NIX_PATH=nixpkgs=${HOME}/code/nixpkgs:nixpkgs-overlays=${HOME}/nixpkgs-overlays-scratch-gpfs/overlays
	export ENVRC=nix-scratch-gpfs
	$(SHELL)
update-packages-lobo:
	set -x
	cluster=lobo
	rm -f pkgs/$$cluster*
	packages=$$(nix-build -o pkgs/$$cluster -E 'with import <nixpkgs> {}; [ nix gitAndTools.git-annex gitAndTools.hub gitFull tree python3 cmake ncurses.all ]')
	nix-copy-closure -v --to $$cluster $$packages
	ssh $$cluster nix-env -i $$packages
clean-packages-%:
	set -x
	cluster=$*
	ssh $$cluster nix-collect-garbage -d

UUID_1=e13483d5-e688-42ea-8ac7-abdfed45bc4c
UUID_2=d8c5a336-76b1-44a6-a49e-8968928f5193
BLURAY_ID=2
BLURAY_UUID=$(UUID_2)
new_bluray:
	#read "are you sure?"
	echo mkfs.udf --utf8 --udfrev=2.01 --label bluray_$(BLURAY_ID) --vsid=$(BLURAY_UUID) --lvid=bluray_$(BLURAY_ID) --vid=bluray_$(BLURAY_ID) --fsid=bluray_$(BLURAY_ID) --fullvsid=bluray_$(BLURAY_ID) /dev/sdb

.PHONY: backup-files.lst
backup-files.lst:
	set -x
	echo > backup-files.lst
	rule=()
	rule+=(--and --not --in bd_17)
	rule+=(--and --not --in c5dcd424-09d3-44b1-aaa0-17eb0ad827f6) # bd_18
	rule+=(--and --not --in 2c1c66ff-7d5f-4787-8799-3503240d75f5) # bd_19
	rule+=(--and --not --in d5066f45-7514-484a-94a0-a46d753d4f09) # bd_20
	rule+=(--and --not --in cd6c7c3e-d994-459a-a6e9-198a9737f597) # bd_21
	rule+=(--and --not --in 44995e74-effb-4a78-9278-d717ca213fb7) # bd_22
	#echo "$$(( 22673114*1024 ))        /media/bd_18" >> backup-files.lst
	echo "$$(( 13354016*1024 ))        /media/bd_22" >> backup-files.lst
	for repo in archives Documents Music work Videos; do
	(cd $$repo; git annex find --format '$${bytesize}  '$$repo' $${file}\n' --include '*' $${rule[@]}) >> $@
	done
	cat backup-files.lst backup-files.lst.size_unknown | grep  "^unknown" | sponge backup-files.lst.size_unknown || true
	grep  -v "^unknown" backup-files.lst | sponge backup-files.lst || true
	grep  -v " adb-oneplusone/" backup-files.lst | sponge backup-files.lst || true
	grep  -v " removable-greenkey16/" backup-files.lst | sponge backup-files.lst || true
	bd_size=$$(( (12219392*2-128*1024)*1024 ))
	bd_size=$$(echo "scale=0; $$bd_size*94/100" | bc -l)
	mkdir -p backups/
	fpart -i backup-files.lst -a -s $$bd_size -o backups/bluray |& tee backups/bluray-parts.log

# 	--lvid=            Logical Volume Identifier (default: LinuxUDF)
#	--vid=             Volume Identifier (default: LinuxUDF)
#	--vsid=            17.-127. character of Volume Set Identifier (default: LinuxUDF)
#	--fsid=            File Set Identifier (default: LinuxUDF)
#	--fullvsid
