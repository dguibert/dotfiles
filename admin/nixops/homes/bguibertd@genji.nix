{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/custom-profile.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;
  withEmacs.enable = true;
  withCustomProfile.enable = true;
  withCustomProfile.suffix = "";

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
  home.sessionPath = [
    "${pkgs.nix}/bin"
  ];

  home.packages = with pkgs; [
    xpra
    bashInteractive

    datalad
    git-annex
  ];
}
