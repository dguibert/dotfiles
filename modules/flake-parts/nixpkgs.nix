{ self, config, pkgs, lib, inputs, perSystem, system, ... }:
let
  packages = config:
    if config.user_config.nixpkgs_with_custom_stdenv or false
    then
    # packages with overriden stdenv
      system: inputs.nixpkgs_with_stdenv.legacyPackages.${system}.appendOverlays [
        self.overlays.default
        inputs.deploy-rs.overlay
        inputs.nxsession.overlay
        #inputs.nixpkgs-wayland.overlay
        inputs.hyprland.overlays.default
      ]
    else
      system: inputs.nixpkgs.legacyPackages.${system}.appendOverlays [
        self.overlays.default
        inputs.deploy-rs.overlay
        inputs.nxsession.overlay
        #inputs.nixpkgs-wayland.overlay
        inputs.hyprland.overlays.default
      ];
in
{
  config._module.args.pkgs = packages config system;

  config.perSystem = { config, self', inputs', pkgs, system, ... }: {
    _module.args.pkgs = packages config system;
    legacyPackages = packages config system;
  };
}
#nixpkgsFor = system:
#    import inputs.nixpkgs.inputs.nixpkgs {
#      inherit system;
#      overlays = inputs.nixpkgs.legacyPackages.${system}.overlays
#        ++ [
#        inputs.deploy-rs.overlay
#        inputs.nxsession.overlay
#        #inputs.nixpkgs-wayland.overlay
#        inputs.hyprland.overlays.default
#        (final: prev: import ../../overlays/default final prev)
#        (final: prev: {
#          pinentry = prev.pinentry.override {
#            enabledFlavors = [ "curses" "tty" ];
#          };
#          coreutils = prev.coreutils.overrideAttrs (o: {
#            doCheck = false;
#            doInstallCheck = false;
#          });
#          libffi = prev.libffi.overrideAttrs (o: {
#            doCheck = false;
#            doInstallCheck = false;
#          });
#          libuv = prev.libuv.overrideAttrs (o: {
#            doCheck = false;
#            doInstallCheck = false;
#          });
#        })
#      ];
#      config = { allowUnfree = true; } // inputs.nixpkgs.legacyPackages.${system}.config;
#      #config.contentAddressedByDefault = true;
#    };
#in
#{
#  perSystem = { config, self', inputs', pkgs, system, ... }: {
#    _module.args.pkgs = nixpkgsFor system;
#  };
#}
