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
gitAndTools.hub # command-line wrapper for git that makes you better at GitHub
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
firefox-bin
htop
tree
gnupg1compat
x2goclient
wpsoffice
file
pass
qtpass
git-credential-password-store
bc
parallel
pandoc
unzip

rclone
gitAndTools.git-annex-remote-rclone
sshfsFuse

go-mtpfs
]
