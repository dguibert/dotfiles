is_feature = $(if $(filter $1,$(.FEATURES)),T)
ifneq ($(call is_feature,oneshell),T)
	$(error This Makefile only works with a Make program that supports "oneshell" feature (version>=3.82))
endif

.ONESHELL:
.POSIX:
HOSTNAME?=$(shell hostname -s)

export ATTR=
export U=
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
secrets-%:
	set -xeuf -o pipefail
	host=$*
	source_path=$(PWD)/secrets
	pass_prefix=$$source_path/$$host
	dest_path=/tmp/$$host
	local_pass_info=$$(git -C $$source_path log -1 --format=%H $$host)
	remote_pass_info=$(ssh $$host cat $$dest_path/.pass_info || :)
	if test "$$local_pass_info" = "$$remote_pass_info"; then
		exit 0
	fi
	tmp_dir=$$(mktemp -dt populate-pass.XXXXXXXX)
	trap cleanup EXIT
	cleanup() {
		rm -fR "$$tmp_dir"
	}
	find $$pass_prefix -type f |
	while read -r gpg_path; do
		rel_name=$${gpg_path#$$pass_prefix/}
		rel_name=$${rel_name%.gpg}
		pass_date=$$(git -C $$source_path log -1 --format=%aI "$$gpg_path")
		pass_name=$$host/$$rel_name
		tmp_path=$$tmp_dir/$$rel_name
		mkdir -p "$$(dirname "$$tmp_path")"
		PASSWORD_STORE_DIR=$$source_path pass show "$$pass_name" > "$$tmp_path"
		touch -d "$$pass_date" "$$tmp_path"
	done
	if test -n "''$${local_pass_info-}"; then
		echo "$$local_pass_info" > "$$tmp_dir"/.pass_info
	fi
	#if [ "$$HOSTNAME" == "$$host" ]; then
	#  rsync --checksum \
	#	  -vFrlptD \
	#	  --delete-excluded \
	#	  $$tmp_dir/ \
	#	  $$dest_path
	#else
	#  rsync --checksum \
	#	  -vFrlptD \
	#	  --delete-excluded \
	#	  $$tmp_dir/ \
	#	  $$host:$$dest_path
	#fi

dguibert-titan: ATTR=hm_dguibert_x11.x86_64-linux
dguibert-vbox-57nvj72: ATTR=hm_dguibert_x11.x86_64-linux
dguibert-orsine: ATTR=hm_dguibert_x11.x86_64-linux
dguibert-rpi31: ATTR=hm_dguibert_nox11.aarch64-linux

root-titan: ATTR=hm_root.x86_64-linux
root-vbox-57nvj72: ATTR=hm_root.x86_64-linux
root-orsine: ATTR=hm_root.x86_64-linux
root-rpi31: ATTR=hm_root.aarch64-linux

dguibert-manny: ATTR=hm_dguibert_manny
dguibert-manny: U=bguibertd
dguibert-genji: ATTR=hm_dguibert_genji
dguibert-genji: U=bguibertd
dguibert-inti: ATTR=hm_dguibert_inti
dguibert-inti: U=bguibertd

dguibert-%:
	set -xeuf -o pipefail
	user=$${U:-dguibert}
	host=$*
	hm=$$(nix-build --no-out-link ./release.nix -A $$ATTR)
	if [ "$$HOSTNAME" == "$$host" ]; then
	  $$hm/activate
	else
	  nix copy --to ssh://$$host $$hm
	  ssh $$user@$$host $$hm/activate
	fi
root-%:
	set -xeuf -o pipefail
	user=root
	host=$*
	hm=$$(nix-build --no-out-link ./release.nix -A $$ATTR)
	if [ "$$HOSTNAME" == "$$host" ]; then
	  sudo -i $$hm/activate
	else
	  nix copy --to ssh://$$host $$hm
	  ssh $$user@$$host $$hm/activate
	fi
