{ self, config, pkgs, lib, inputs, perSystem, system, ... }:
let
  overlays = [
    self.overlays.default
    inputs.deploy-rs.overlay
    inputs.nxsession.overlay
    #inputs.nixpkgs-wayland.overlay
    inputs.hyprland.overlays.default
  ];

  packages = config:
    if config.user_config.nixpkgs_with_custom_stdenv or false
    then
    # packages with overriden stdenv
      system: inputs.nixpkgs_with_stdenv.legacyPackages.${system}.appendOverlays overlays
    else
      system: inputs.nixpkgs.legacyPackages.${system}.appendOverlays overlays
  ;
in
{
  config._module.args.pkgs = packages config system;

  config.perSystem = { config, self', inputs', pkgs, system, ... }: {
    _module.args.pkgs = packages config system;
    legacyPackages = packages config system;
  };
}
