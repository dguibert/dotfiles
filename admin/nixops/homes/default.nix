{ lib
, inputs
, outputs
, nixpkgs_to_use ? { default = inputs.nixpkgs; }
, systems ? { default = "x86_64-linux"; }
, ...
}:

with lib;

mapAttrs'
  (name: type:
  let
    name' = removeSuffix ".nix" name;
  in
  {
    name = name';
    value =
      let
        file = ./. + "/${name}";
        nixpkgs_ = nixpkgs_to_use.${name'} or nixpkgs_to_use.default;
        system_ = systems.${name'} or systems.default;
      in
      builtins.trace "evaluating home-manager for ${name'} (${system_})"
        inputs.home-manager.lib.homeManagerConfiguration
        {
          pkgs = nixpkgs_.${system_}; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inputs = inputs // { nixpkgs = nixpkgs_; };
            inherit outputs;
            sopsDecrypt_ = nixpkgs_.${system_}.sopsDecrypt_;
          };
          modules = [
            # > Our main home-manager configuration file <
            (import file)
          ];
        };
  })
  (filterAttrs
    (name: type:
    (type == "directory" && builtins.pathExists "${toString ./.}/${name}/default.nix") ||
    (type == "regular" && hasSuffix ".nix" name && ! (hasSuffix "@.nix" name) && ! (name == "default.nix") && ! (name == "overlays.nix")) ||
    (type == "symlink" && hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix") && ! (name == "common.nix"))
    )
    (builtins.readDir ./.))