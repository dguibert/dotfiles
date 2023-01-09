{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/custom-profile.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;
  withEmacs.enable = false;
  withCustomProfile.enable = true;
  withCustomProfile.suffix = "";

  nixpkgs.overlays = [
    inputs.nur_dguibert.overlays.cluster
    inputs.nur_dguibert.overlays.store-levante
  ];
  home.username = "b381115";
  home.homeDirectory = "/home/b/b381115";
  home.stateVersion = "22.11";
  #home.activation.setNixVariables = lib.hm.dag.entryBefore ["writeBoundary"]
  home.sessionPath = [
    "${pkgs.nix}/bin"
  ];

  # additional programs
  home.packages = with pkgs; [
    xpra
    bashInteractive

    datalad
    git-annex
  ];
}
