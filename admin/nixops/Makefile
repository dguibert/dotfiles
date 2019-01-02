is_feature = $(if $(filter $1,$(.FEATURES)),T)
ifneq ($(call is_feature,oneshell),T)
	$(error This Makefile only works with a Make program that supports "oneshell" feature (version>=3.82))
endif

.ONESHELL:
.POSIX:
HOSTNAME?=$(shell hostname -s)

export ATTR=
build:
	nix-build --no-out-link ./release.nix
host-%:
	set -xeuf -o pipefail
	host=$*
	profile=/nix/var/nix/profiles/system
	pathToConfig=$$(nix-build --no-out-link ./release.nix -A $$host)
	if [ "$$HOSTNAME" == "$$host" ]; then
	  sudo -E nix-env -p $$profile --set $$pathToConfig
	  sudo -E $$pathToConfig/bin/switch-to-configuration switch
	else
	  nix copy --to ssh://root@$$host $$pathToConfig
	  ssh root@$$host nix-env -p $$profile --set $$pathToConfig
	  ssh root@$$host $$pathToConfig/bin/switch-to-configuration switch
	fi

dguibert-titan: ATTR=hm_dguibert_x11.x86_64-linux
dguibert-orsine: ATTR=hm_dguibert_x11.x86_64-linux
dguibert-rpi31: ATTR=hm_dguibert_nox11.aarch64-linux
dguibert-%:
	set -xeuf -o pipefail
	user=dguibert
	host=$*
	if [ "$$HOSTNAME" == "$$host" ]; then
	  $$(nix-build ./release.nix -A $$ATTR)/activate
	else
	  nix copy --to ssh://$$host $$(nix-build ./release.nix -A $$ATTR)
	  ssh $$user@$$host $$(nix-build ./release.nix -A hm_$${user}_x11.x86_64-linux)/activate
	fi
