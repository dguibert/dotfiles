.ONESHELL:
.POSIX:
#.SHELLFLAGS=-x -c

all:

.PHONY:nix
nix:
	export ENVRC=nix
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
	ssh $$cluster mkdir -p ~/bin ~/public_git
	ssh $$cluster git init --bare ~/public_git/dotfiles.git
	scp ~/bin/mgit $$cluster:bin/
	(cd ~/public_git/dotfiles.git; git push --all ssh://$$cluster/~/public_git/dotfiles.git )
	ssh $$cluster mgit clone file://public_git/dotfiles.git

init-nix-%:
	set -x
	cluster=$*
	#curl -C - -O https://nixos.org/releases/nix/nix-1.11.13/nix-1.11.13-x86_64-linux.tar.bz2
	rsync -aP nix-1.11.13-x86_64-linux.tar.bz2 $$cluster:
	ssh $$cluster "(mkdir -p ~/pkgs/nix-mnt; cd ~/pkgs/nix-mnt; tar xv --strip-components=1 -f ~/nix-1.11.13-x86_64-linux.tar.bz2; proot-x86_64 -b ~/pkgs/nix-mnt:/nix ./install)"

# nix-copy-closure -v --to manny $(nix-build --arg expr "(import <nixpkgs> {}).nix" --keep-going -Q ./maintainers/scripts/all-sources.nix -I nixpkgs=$HOME/code/nixpkgs)
update-packages-%:
	set -x
	cluster=$*
	rm -f pkgs/$$cluster*
	packages=$$(nix-build -o pkgs/$$cluster $$HOME/.nixpkgs/my-packages@cluster.nix)
	nix-copy-closure -v --to $$cluster $$packages
	ssh $$cluster nix-env -i $$packages
clean-packages-%:
	set -x
	cluster=$*
	ssh $$cluster nix-collect-garbage -d
