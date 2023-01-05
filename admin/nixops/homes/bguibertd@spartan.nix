{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/emacs.nix
    ./dguibert/custom-profile.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;
  withCustomProfile.enable = true;
  withCustomProfile.suffix = "";

  nixpkgs.overlays = [
    inputs.nur_dguibert.overlays.cluster
    inputs.nur_dguibert.overlays.store-spartan
  ];
  home.username = "bguibertd";
  home.homeDirectory = "/home_nfs/bguibertd";
  home.stateVersion = "22.11";
  #home.activation.setNixVariables = lib.hm.dag.entryBefore ["writeBoundary"]
  programs.bash.bashrcExtra = /*(homes.withoutX11 args).programs.bash.initExtra +*/ ''
    # support for x86_64/aarch64
    # include .bashrc if it exists
    [[ -f ~/.bashrc.$(uname -m) ]] && . ~/.bashrc.$(uname -m)
  '';
  programs.bash.profileExtra = ''
    # support for x86_64/aarch64
    # include .profile if it exists
    [[ -f ~/.profile.$(uname -m) ]] && . ~/.profile.$(uname -m)
  '';

}
