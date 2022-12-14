{ config, pkgs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/emacs.nix
  ];
  withGui.enable = true;

  home.username = "dguibert";
  home.homeDirectory = "/home/dguibert";
  home.stateVersion = "22.11";
}
