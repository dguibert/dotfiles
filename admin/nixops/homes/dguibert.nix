{ config, lib, inputs, withSystem, self, ... }:
let
  genHomeManagerConfiguration = import ../lib/gen-home-manager-configuration.nix { inherit lib; };
in
{
  imports = [
    (genHomeManagerConfiguration "aarch64-linux" "dguibert@rpi31")
    (genHomeManagerConfiguration "aarch64-linux" "dguibert@rpi41")
    (genHomeManagerConfiguration "x86_64-linux" "dguibert@t580")
    (genHomeManagerConfiguration "x86_64-linux" "dguibert@titan")
  ];

  modules.homes."dguibert@rpi31" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/home-manager/dguibert.nix
      ];
      withGui.enable = false;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

  modules.homes."dguibert@rpi41" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/home-manager/dguibert.nix
      ];
      withGui.enable = false;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

  modules.homes."dguibert@t580" = [
    ../modules/home-manager/dguibert.nix
    ({ config, pkgs, ... }: {
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.package = pkgs.hyprland;
      withGui.enable = true;
      withEmacs.enable = true;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

  modules.homes."dguibert@titan" = [
    ../modules/home-manager/dguibert.nix
    ({ config, pkgs, ... }: {
      #wayland.windowManager.hyprland.enable = true;
      centralMailHost.enable = true;
      withGui.enable = true;
      withEmacs.enable = true;
      withZellij.enable = true;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

}


