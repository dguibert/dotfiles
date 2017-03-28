.ONESHELL:
.POSIX:
#.SHELLFLAGS=-x -c

all:

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
	export BUP_DIR=$(HOME)/annex/bup
	test ! -d $$BUP_DIR && bup init
	bup index \
		--exclude=$(HOME)/.git \
		--exclude=$(HOME)/annex/.git/annex \
		--exclude=$$BUP_DIR \
		$(HOME)
	bup save -n home-$$(hostname) $(HOME)
	
	#Defend your backups from death rays (OK fine, more likely from the occasional bad disk block). This writes parity information (currently via par2) for all of the existing data so that bup may be able to recover from some amount of repository corruption:
	
	bup fsck -g

	cd $(HOME)/annex
	git annex add $$BUP_DIR/objects/pack
	git annex proxy -- git add $${BUP_DIR##$(HOME)/annex/}
	git annex proxy -- git add bup
	git annex proxy -- git commit -m "Backup on $$(date)"
	git annex sync --content
