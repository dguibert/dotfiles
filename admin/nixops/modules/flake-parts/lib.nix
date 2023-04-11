{ self, lib, inputs, ... }: {
  flake.lib =
    let
      l = lib // builtins;
    in
    inputs.nixpkgs.lib // {
      genHomeManagerConfiguration = import ../../lib/gen-home-manager-configuration.nix { inherit lib; };
    };
}
