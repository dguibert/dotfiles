# nix-env -f ~/.nixpkgs/my-packages.nix -ir
# nix-env -f ~/.nixpkgs/my-packages.nix -ir -I nixpkgs=$HOME/code/nixpkgs/
with import <nixpkgs> {};
let
 previousPkgs_pu = import (fetchTarball https://github.com/dguibert/nixpkgs/archive/221683611736b6ff91479ed0aadbf58e31312247.tar.gz) {};
in
[
vim
editorconfig-core-c

nix-prefetch-scripts

mpv
python3
pythonPackages.subliminal
#previousPkgs_pu.gitAndTools.git-annex
rsync
mr
mercurial

gitFull
gitAndTools.git-annex
gitAndTools.gitRemoteGcrypt
gitAndTools.git-crypt
gitAndTools.git-annex-remote-rclone
rclone
gitAndTools.hub # command-line wrapper for git that makes you better at GitHub

dwm dmenu xlockmore xautolock xorg.xset xorg.xinput xorg.xsetroot xorg.setxkbmap xorg.xmodmap rxvt_unicode st
(conky.override { x11Support = false; })

asciidoc
baobab
bup
par2cmdline

ctags
direnv
dvtm

gnumake
gnuplot
jq
mkpasswd
nix-repl
nox
pstree
ruby
screen
#teamviewer
tig
virtualgl
mosh
lsof
xpra
aria2
nixops
haskellPackages.nix-deploy
#chromium
google-chrome
firefox-bin
htop
tree
gnupg1compat
x2goclient
#wpsoffice
file
pass
qtpass
browserpass
git-credential-password-store
bc
parallel
pandoc
unzip

sshfsFuse

go-mtpfs

wayland
sway

corkscrew
autossh

davmail
thunderbird
]
