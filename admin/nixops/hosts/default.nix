{ lib
, inputs
, outputs
, nixpkgs_to_use ? { default = inputs.nixpkgs; }
, systems ? { }
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
        system = systems.${name} or "x86_64-linux";
      in
      builtins.trace "evaluating nixosSystem for ${name}"
        nixpkgs_.inputs.nixpkgs.lib.nixosSystem
        {
          inherit system;
          specialArgs = {
            pkgs = inputs.self.legacyPackages.${system};
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
    (type == "regular" && hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix"))
    )
    (builtins.readDir ./.))
