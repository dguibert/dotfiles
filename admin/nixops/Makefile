is_feature = $(if $(filter $1,$(.FEATURES)),T)
ifneq ($(call is_feature,oneshell),T)
	$(error This Makefile only works with a Make program that supports "oneshell" feature (version>=3.82))
endif

.ONESHELL:
.POSIX:
HOSTNAME?=$(shell hostname -s)

build:
	nix-build --no-out-link ./release.nix ${MAKE_FLAGS}
host-%:
	set -x
	host=$*
	if [ "$$HOSTNAME" == "$$host" ]; then
	  sudo -E $$(nix-build --no-out-link ./release.nix -A $$host)/bin/switch-to-configuration switch
	else
	   nix copy --to ssh://root@$$host $$(nix-build --no-out-link ./release.nix -A $$host)
	  ssh root@$$host $$(nix-build --no-out-link ./release.nix -A $$host)/bin/switch-to-configuration switch
	fi

dguibert-%:
	set -x
	user=dguibert
	host=$*
	if [ "$$HOSTNAME" == "$$host" ]; then
	  $$(nix-build ./release.nix -A hm_$${user}_x11.x86_64-linux)/activate
	else
	  nix copy --to ssh://$$host $$(nix-build ./release.nix -A hm_$${user}_x11.x86_64-linux)
	  ssh $$user@$$host $$(nix-build ./release.nix -A hm_$${user}_x11.x86_64-linux)/activate
	fi
