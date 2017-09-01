# nix-env -f ~/.nixpkgs/my-packages.nix -ir
# nix-env -f ~/.nixpkgs/my-packages.nix -ir -I nixpkgs=$HOME/code/nixpkgs/
with import <nixpkgs> {};
[
gitAndTools.git-annex
gitAndTools.git-crypt
gitFull #guiSupport is harmless since we also installl xpra
tig
direnv
jq
lsof
xpra
htop
tree
]
