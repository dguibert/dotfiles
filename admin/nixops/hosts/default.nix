{ lib
, inputs
, outputs
, nixpkgs_to_use ? { default = inputs.nixpkgs; }
, ...
}:

with lib;

mapAttrs'
  (name: type: {
    name = removeSuffix ".nix" name;
    value =
      let
        file = ./. + "/${name}";
        nixpkgs_ = nixpkgs_to_use.${name} or nixpkgs_to_use.default;
      in
      builtins.trace "evaluating nixosSystem for ${name}"
        nixpkgs_.lib.nixosSystem
        {
          specialArgs = {
            inputs = inputs // { nixpkgs = nixpkgs_; };
            inherit outputs;
          };
          modules = [
            (import file)
          ];
        };
  })
  (filterAttrs
    (name: type:
    (type == "directory" && builtins.pathExists "${toString ./.}/${name}/default.nix") ||
    (type == "regular" && hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix") && ! (name == "common.nix"))
    )
    (builtins.readDir ./.))
