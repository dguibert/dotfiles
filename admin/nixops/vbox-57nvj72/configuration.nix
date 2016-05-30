{ config, pkgs, lib, ... }:
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix> ];

  i18n.consoleKeyMap="fr";

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ vim vcsh gitFull ];

  fileSystems."/a629925" = {
    fsType = "vboxsf";
    device = "a629925";
    options = [ "rw" ];
  };
  zramSwap.enable = true;

  # Users
  nixup.enable = true;

  users.users.dguibert = {
    uid = 1000;
    isNormalUser = true;
    description = "David Guibert";
    group = "dguibert";
    extraGroups = [ "dguibert" "wheel" "users" "disk" "video" "audio" "adm" ]
      ++ lib.optionals (config.users.groups ? vboxuser) [ "vboxuser" ]
      ++ lib.optionals (config.users.groups ? vboxsf) [ "vboxsf" ]
      ++ lib.optionals (config.users.groups ? docker) [ "docker" ]
    ;
  };

  users.groups.dguibert.gid = 1000;

  programs.bash.enableCompletion = true;
  environment.shellInit = ''
    export NIX_PATH=nixpkgs=https://github.com/dguibert/nixpkgs/archive/pu.tar.gz:nixos-config=$HOME/admin/nixops/$(hostname)/configuration.nix
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.startWhenNeeded = true;
  
  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "fr,us";
  services.xserver.xkbOptions = "eurosign:e";

  # fonts
  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.enableCoreFonts = true;
  fonts.fonts = with pkgs ; [ terminus_font ];

  #X11 and Gnome3
  #services.xserver.desktopManager.default = "gnome3";
  #services.xserver.desktopManager.gnome3.enable = true;

  nix.useChroot = true;
  nix.extraOptions = "auto-optimise-store = true";
  nix.binaryCachePublicKeys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];

  # Enable ZeroTierOne
  services.zerotierone.enable = true;
  networking.firewall.allowedUDPPorts = [ 9993 ];

  services.cntlm.enable = true;
  services.cntlm.username = "a629925";
  services.cntlm.domain = "ww930";
  services.cntlm.netbios_hostname = "fr-57nvj72";
  services.cntlm.proxy = [
    "10.89.0.72:84"
  ];
  services.cntlm.extraConfig = ''
NoProxy localhost, 127.0.0.*, 10.*, 192.168.*
  '';
}
