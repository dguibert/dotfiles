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
      builtins.trace "evaluating app for ${name'} (${system_})"
        import
        file
        {
          pkgs = nixpkgs_.${system_}; # Home-manager requires 'pkgs' instance
          inputs = inputs // { nixpkgs = nixpkgs_; };
          inherit outputs;
        };
  })
  (filterAttrs
    (name: type:
    (type == "directory" && builtins.pathExists "${toString ./.}/${name}/default.nix") ||
    (type == "regular" && hasSuffix ".nix" name && ! (hasSuffix "@.nix" name) && ! (name == "default.nix") && ! (name == "overlays.nix")) ||
    (type == "symlink" && hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix") && ! (name == "common.nix"))
    )
    (builtins.readDir ./.))
