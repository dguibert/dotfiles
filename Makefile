.ONESHELL:
.POSIX:
#.SHELLFLAGS=-x -c

all:

.PHONY:nix
nix:
	export ENVRC=nix
	export NIX_PATH=nixpkgs=$$HOME/code/nixpkgs
	proot-x86_64 -b ~/pkgs/nix-mnt:/nix bash

_SHELL:=$(shell echo $$SHELL)
export SHELL=$(_SHELL)
atos_proxy:
	export http_proxy=http://a629925:$$(pass show bull/das | head -n1)@localhost:3128
	export https_proxy=$$http_proxy
	export ENVRC=$${ENVRC}+atos_proxy
	$(SHELL)

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

update-host:
	cd ~/admin/nixops
	source .envrc
	nixops deploy -I nixpkgs=$$HOME/code/nixpkgs --option allow-unsafe-native-code-during-evaluation true --include $$HOSTNAME
update-hosts:
	cd ~/admin/nixops
	source .envrc
	nixops deploy -I nixpkgs=$$HOME/code/nixpkgs -option allow-unsafe-native-code-during-evaluation true
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
BLURAY_ID=1
BLURAY_UUID=$(UUID_1)
new_bluray:
	#read "are you sure?"
	echo mkfs.udf --utf8 --udfrev=2.01 --label bluray_$(BLURAY_ID) --vsid=$(BLURAY_UUID) --lvid=bluray_$(BLURAY_ID) --vid=bluray_$(BLURAY_ID) --fsid=bluray_$(BLURAY_ID) --fullvsid=bluray_$(BLURAY_ID) /dev/sdb


# 	--lvid=            Logical Volume Identifier (default: LinuxUDF)
#	--vid=             Volume Identifier (default: LinuxUDF)
#	--vsid=            17.-127. character of Volume Set Identifier (default: LinuxUDF)
#	--fsid=            File Set Identifier (default: LinuxUDF)
#	--fullvsid
