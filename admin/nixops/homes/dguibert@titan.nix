{ config, pkgs, ... }:
{
  imports = [
    ./dguibert/home.nix
  ];
  centralMailHost.enable = true;
  withGui.enable = true;
  withEmacs.enable = true;
  withZellij.enable = true;

  home.username = "dguibert";
  home.homeDirectory = "/home/dguibert";
  home.stateVersion = "22.11";
}
