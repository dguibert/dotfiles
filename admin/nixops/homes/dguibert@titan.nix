{ config, pkgs, inputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    inputs.hyprland.homeManagerModules.default
    {
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.nvidiaPatches = true;
      wayland.windowManager.hyprland.extraConfig = builtins.readFile ./dguibert/hyprland.conf;
      services.swayidle.enable = true;
      services.swayidle.timeouts = [
        { timeout = 305; command = "${pkgs.swaylock}/bin/swaylock -f -c 000000"; }
        { timeout = 300; command = "hyprland dispatch dpms off"; }
      ];
      services.swayidle.events = [
        { event = "after-resume"; command = "hyprland dispatch dpms on"; }
        { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f -c 000000'"; }
        { event = "lock"; command = "lock"; }
      ];
      services.swayidle.systemdTarget = "hyprland-session.target";
    }
  ];
  centralMailHost.enable = true;
  withGui.enable = true;
  withEmacs.enable = true;
  withZellij.enable = true;

  home.username = "dguibert";
  home.homeDirectory = "/home/dguibert";
  home.stateVersion = "22.11";
}
