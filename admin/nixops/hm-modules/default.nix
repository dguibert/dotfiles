{ lib, ... }:

with lib;

mapAttrs'
  (name: type: {
    name = removeSuffix ".nix" name;
    value = let file = ./. + "/${name}"; in
      import file;
  })
  (filterAttrs
    (name: type:
    (type == "directory" && builtins.pathExists "${toString ./.}/${name}/default.nix") ||
    (type == "regular" && hasSuffix ".nix" name && ! (name == "default.nix") && ! (name == "overlays.nix"))
    )
    (builtins.readDir ./.))
