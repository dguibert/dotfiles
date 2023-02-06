{ config, lib, pkgs, outputs, inputs, ... }: {
  #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
  #nixpkgs.localSystem.system = "x86_64-linux";
  nixpkgs.localSystem.system = "aarch64-linux";
  imports = [
    (import "${inputs.nixpkgs.inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
    (import ./configuration.nix)
    outputs.nixosModules.defaults
  ];
  nixpkgs.overlays = [
    (final: prev: {
      # don't build qt5
      # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
      pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
    })
  ];

  programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";
  #assertions = lib.singleton {
  #  assertion = pkgs.stdenv.system == "aarch64-linux";
  #  message = "rpi31-configuration.nix can be only built natively on Aarch64 / ARM64; " +
  #    "it cannot be cross compiled";
  #};
}
