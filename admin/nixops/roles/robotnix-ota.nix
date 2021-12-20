{ config, lib, pkgs, ... }:
let
  cfg = config.roles.tiny-ca;
in
{
  # https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/
  options.roles.robotnix-ota-server = {
    enable = lib.mkOption {
      default = false;
      description = "Wether to enable OTA role for robotnix";
      type = lib.types.bool;
    };
    openFirewall = lib.mkEnableOption "opening the certificate authority server port";
  };

  config = lib.mkIf cfg.enable {
    services.nginx.enable = true;
    services.nginx.virtualHosts."192.168.1.24" = {
      listen = [{ addr="192.168.1.24"; port=80; }];
      #root = "/nix/var/nix/profiles/per-user/dguibert/ota-dir";
      locations."/android".root = "/nix/var/nix/profiles/per-user/dguibert/ota-dir";
    };

    networking.firewall.interfaces.bond0.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      80
    ];
  };
}
