{ config, pkgs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/emacs.nix
  ];
  centralMailHost.enable = true;
  withGui.enable = true;

  home.username = "dguibert";
  home.homeDirectory = "/home/dguibert";
  home.stateVersion = "22.11";
}
