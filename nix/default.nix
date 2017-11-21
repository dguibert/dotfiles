let
 _nixpkgs = import <nixpkgs> { config = {}; overlays = []; };
 #nix-prefetch-git https://github.com/dguibert/nixpkgs refs/heads/pu > nixpkgs-src.json
 spec = builtins.fromJSON (builtins.readFile ./nixpkgs-src.json);
in
{ nixpkgsSrc ? _nixpkgs.fetchFromGitHub {
		 owner = "dguibert";
		 repo = "nixpkgs";
                 inherit (spec) rev sha256;
               }
}:
import nixpkgsSrc {
 # Makes the config pure as well.
 # See <nixpkgs>/top-level/impure.nix:
 config = { };
 overlays = [ (import ./all-packages.nix) ];
}
