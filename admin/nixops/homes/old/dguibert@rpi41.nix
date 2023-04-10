{ config, pkgs, ... }:
{
  imports = [
    ./dguibert/home.nix
  ];
  withGui.enable = false;

  home.username = "dguibert";
  home.homeDirectory = "/home/dguibert";
  home.stateVersion = "22.11";
}