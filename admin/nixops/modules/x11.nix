{ config, lib, pkgs, ... }:
{
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "fr";
  services.xserver.xkbOptions = "eurosign:e";

  #services.xserver.videoDrivers = [ "intel" "displaylink" ]; # error: Package ‘evdi-1.4.1+git2017-06-12’ in /home/dguibert/code/nixpkgs/pkgs/os-specific/linux/evdi/default.nix:26 is marked as broken, refusing to evaluate.
  hardware.opengl.driSupport32Bit = true;

#  services.xserver.desktopManager.default = "gnome3";
#  services.xserver.desktopManager.gnome3.enable = true;
#  networking.wireless.enable = mkForce false; # - You can not use networking.networkmanager with services.networking.wireless
# TODO check incompatibilities with home-manager xsession
  services.xserver.displayManager.auto.enable = true;
  services.xserver.displayManager.auto.user = "dguibert";
  services.xserver.desktopManager.xterm.enable = true;

  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.enableCoreFonts = true;
  fonts.fonts = with pkgs ; [ terminus_font powerline-fonts ];

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.kdm.enable = true;
  # services.xserver.desktopManager.kde4.enable = true;

  security.wrappers.xlock.source = "${pkgs.xlockmore}/bin/xlock";
}

