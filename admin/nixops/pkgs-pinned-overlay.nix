{ system ? builtins.currentSystem }:
let
  pkgs_master = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz)       { inherit system; };
  pkgs_nix_2_0 = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/nix-2.0.tar.gz)     { inherit system; };
  pkgs_17_09 = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/release-17.09.tar.gz) { inherit system; };
in self: super: {
  #nix = pkgs_nix_2_0.nix;
  #pandoc = pkgsMaster.pandoc;
}
