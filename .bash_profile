# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

if [ -e /home_nfs/bguibertd/.nix-profile/etc/profile.d/nix.sh ]; then . /home_nfs/bguibertd/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
