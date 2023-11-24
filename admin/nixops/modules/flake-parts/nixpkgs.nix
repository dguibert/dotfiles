{ inputs, perSystem, ... }:
let
  nixpkgsFor = system:
    import inputs.nixpkgs.inputs.nixpkgs {
      inherit system;
      overlays = inputs.nixpkgs.legacyPackages.${system}.overlays
        ++ [
        inputs.deploy-rs.overlay
        inputs.sops-nix.overlays.default
        inputs.nxsession.overlay
        #inputs.nixpkgs-wayland.overlay
        inputs.hyprland.overlays.default
        (final: prev: import ../../overlays/default final prev)
        (final: prev: {
          pinentry = prev.pinentry.override {
            enabledFlavors = [ "curses" "tty" ];
          };
          coreutils = prev.coreutils.overrideAttrs (o: {
            doCheck = false;
            doInstallCheck = false;
          });
          libffi = prev.libffi.overrideAttrs (o: {
            doCheck = false;
            doInstallCheck = false;
          });
          libuv = prev.libuv.overrideAttrs (o: {
            doCheck = false;
            doInstallCheck = false;
          });
        })
      ];
      config = { allowUnfree = true; } // inputs.nixpkgs.legacyPackages.${system}.config;
      #config.contentAddressedByDefault = true;
    };
in
{
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    _module.args.pkgs = nixpkgsFor system;
  };
}
