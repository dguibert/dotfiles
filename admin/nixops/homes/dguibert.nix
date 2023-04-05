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
        ../modules/homes/dguibert/home.nix
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
        ../modules/homes/dguibert/home.nix
      ];
      withGui.enable = false;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

  modules.homes."dguibert@t580" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/homes/dguibert/home.nix
      ];
      withGui.enable = true;
      withEmacs.enable = true;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

  modules.homes."dguibert@titan" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/homes/dguibert/home.nix
      ];
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


