{ config, lib, pkgs, ... }:
let
  cfg = config.role.robotnix-ota-server;
in
{
  # https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/
  options.role.robotnix-ota-server = {
    enable = lib.mkOption {
      default = false;
      description = "Wether to enable OTA role for robotnix";
      type = lib.types.bool;
    };
    openFirewall = lib.mkEnableOption "opening the certificate authority server port";
  };

  config = lib.mkIf cfg.enable {
    networking.hosts = {
      "192.168.1.24" = [ "ota.orsin.net" ];
    };

    services.nginx.enable = true;
    # https://docs.robotnix.org/modules/ota.html
    systemd.services.nginx.serviceConfig.ProtectHome = "read-only";
    systemd.services.nginx.serviceConfig.ReadOnlyPaths = [ "/var/www" ];
    services.nginx.virtualHosts."ota.orsin.net" = {
      forceSSL = true;
      #onlySSL = true;
      enableACME = true;

      root = "/var/www/ota.orsin.net";
      #listen = [
      #  { addr="192.168.1.24"; port=443; }
      #];
      extraConfig = ''
                ssl_protocols       TLSv1.2 TLSv1.3;
        	ssl_ciphers         HIGH:!aNULL:!MD5;
                autoindex on;
                autoindex_exact_size off;
      '';
      #root = "/nix/var/nix/profiles/per-user/dguibert/ota-dir";
      locations."/android/" = {
        root = "/var/www/ota.orsin.net";
        tryFiles = "$uri $uri/ =404";
      };
    };

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "david.guibert+certs@gmail.com";
    security.acme.defaults.server = "https://localhost:9443/acme/acme/directory";

    networking.firewall.interfaces."bond0".allowedTCPPorts = lib.mkIf cfg.openFirewall [
      80
      443
    ];
  };
}
