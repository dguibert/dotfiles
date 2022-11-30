{ config, pkgs, ... }:
{
  imports = [
    ./dguibert/home.nix
  ];
  withGui.enable = true;

  home.username = "dguibert";
  home.homeDirectory = "/home/dguibert";
  home.stateVersion = "22.11";
}
