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
	ssh-copy-id -i ~/.ssh/id_bull.pub $$cluster
	ssh $$cluster mkdir -p bin
	scp ~/bin/mgit $$cluster:
	ssh -vvvv $$cluster ./mgit clone ssh://dguibert@localhost:33122/home/dguibert/public_git/dotfiles.git
	rsync -aP .vim/ $$cluster:.vim/ --exclude view

init-nix-%:
	set -x
	cluster=$*
	#curl -C - -O https://nixos.org/releases/nix/nix-1.11.16/nix-1.11.16-x86_64-linux.tar.bz2
	rsync -aP nix-1.11.16-x86_64-linux.tar.bz2 $$cluster:
	ssh $$cluster "(mkdir -p ~/pkgs/nix-mnt; cd ~/pkgs/nix-mnt; tar xv --strip-components=1 -f ~/nix-1.11.16-x86_64-linux.tar.bz2; proot-x86_64 -b ~/pkgs/nix-mnt:/nix ./install)"

update-host:
	cd ~/admin/nixops
	source .envrc
	nixops deploy -I nixpkgs=$$HOME/code/nixpkgs --include $$HOSTNAME
update-hosts:
	cd ~/admin/nixops
	source .envrc
	nixops deploy -I nixpkgs=$$HOME/code/nixpkgs
update-packages:
	nix-env -f $$HOME/.config/nixpkgs/my-packages.nix -ir -I nixpkgs=$$HOME/code/nixpkgs/ --show-trace
	nix-env -if https://github.com/cachix/cachix/tarball/master --substituters https://cachix.cachix.org --trusted-public-keys cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDb
# nix-copy-closure -v --to manny $(nix-build --arg expr "(import <nixpkgs> {}).nix" --keep-going -Q ./maintainers/scripts/all-sources.nix -I nixpkgs=$HOME/code/nixpkgs)
update-packages-%:
	set -x
	cluster=$*
	rm -f pkgs/$$cluster*
	nix build -o pkgs/$$cluster -f $$HOME/.config/nixpkgs/my-packages@cluster.nix
	packages=$$(readlink pkgs/$$cluster*)
	nix copy -v --to ssh://$$cluster $$packages
	ssh $$cluster nix-env -i $$packages
update-packages-juelich:
	set -x
	cluster=juelich
	rm -f pkgs/$$cluster*
	packages=$$(nix-build -o pkgs/$$cluster -E 'with import <nixpkgs> {}; [ gitAndTools.git-annex gitAndTools.hub gitFull tree python3 cmake ncurses.all ]')
	nix-copy-closure -v --to $$cluster $$packages
	ssh $$cluster nix-env -i $$packages
clean-packages-%:
	set -x
	cluster=$*
	ssh $$cluster nix-collect-garbage -d
