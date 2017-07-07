# nix-env -f ~/.nixpkgs/my-packages.nix -ir
# nix-env -f ~/.nixpkgs/my-packages.nix -ir -I nixpkgs=$HOME/code/nixpkgs/
with import <nixpkgs> {};
let
 previousPkgs_pu = import (fetchTarball https://github.com/dguibert/nixpkgs/archive/221683611736b6ff91479ed0aadbf58e31312247.tar.gz) {};
in
[
vim
mpv
pythonPackages.subliminal
#previousPkgs_pu.gitAndTools.git-annex
gitAndTools.git-annex
rsync
mr
vcsh
gitFull
mercurial
(conky.override { x11Support = false; })
fossil
gitAndTools.gitRemoteGcrypt
gitAndTools.git-crypt
dwm dmenu xlockmore xautolock xorg.xset xorg.xinput xorg.xsetroot xorg.setxkbmap xorg.xmodmap rxvt_unicode st
asciidoc
baobab
bup
par2cmdline
cabal2nix
ctags
direnv
doxygen
dvtm
ftop
gnumake
gnuplot
iotop
jq
mkpasswd
mr
nix-repl
nox
pmount
pstree
python
ruby
screen
#teamviewer
tig
vagrant
valgrind
vcsh
virtualgl
mosh
lsof
xpra
aria2
nixops
#chromium
google-chrome
htop
tree
gnupg1compat
x2goclient
wpsoffice
file
pass
qtpass
bc
parallel
pandoc
unzip

rclone
#git-annex-remote-rclone
sshfsFuse

go-mtpfs
]
