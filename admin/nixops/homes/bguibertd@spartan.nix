{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/custom-profile.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;
  withCustomProfile.enable = true;
  withCustomProfile.suffix = "";

  home.username = "bguibertd";
  home.homeDirectory = "/home_nfs/bguibertd";
  home.stateVersion = "22.11";
  #home.activation.setNixVariables = lib.hm.dag.entryBefore ["writeBoundary"]

  # don't use full bash config
  withBash.enable = false;
  programs.bash.enable = true;
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

  home.packages = with pkgs; [
    subversion
    dtach
  ];
}
