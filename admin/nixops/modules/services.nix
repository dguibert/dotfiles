{ config, lib, inputs, outputs, ... }:

let
  cfg = config.empty;

  distribution = with outputs.nixosConfigurations; {
    # 443: shadowsocks+ssh
    haproxy = [ rpi41 ];
    adb = [ titan t580 ];
    jellyfin = [ titan ];
    role-libvirtd = [ titan ];
    role-tinyca = [ titan ];
    role-robotnix-ota-server = [ titan ];
    role-mopidy = [ ];
    desktop = [ titan t580 ];
    server-3Dprinting = [ rpi31 ];
    zigbee = [ rpi41 ];
    platypush = [ titan rpi41 ];
  };

  dispatch_on = hosts: builtins.any (x: x.config.networking.hostName == config.networking.hostName) hosts;
in
{
  imports = [
    # jellyfin
    ()
      # role-tinyca
      outputs.nixosModules.role-tiny-ca
      ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.role-tinyca) {
        role.tiny-ca.enable = true;
        services.step-ca.intermediatePasswordFile = config.sops.secrets.orsin-ca-intermediatePassword.path;
        sops.secrets.orsin-ca-intermediatePassword = {
          sopsFile = ../secrets/defaults.yaml;
        };
        networking.firewall.interfaces."bond0".allowedTCPPorts = [
          config.services.step-ca.port
        ];
      })
      # role-robotnix-ota-server
      outputs.nixosModules.role-robotnix-ota
      ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.role-robotnix-ota-server) {
        role.robotnix-ota-server.enable = true;
        role.robotnix-ota-server.openFirewall = true;
      })
      # mopidy-server
      outputs.nixosModules.role-mopidy
      ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.role-mopidy) {
        role.mopidy-server.enable = true; # TODO migrate to pipewire
        role.mopidy-server.listenAddress = "192.168.1.24";
        role.mopidy-server.configuration.local.media_dir = "/home/dguibert/Music/mopidy";
        role.mopidy-server.configuration.m3u = {
          enabled = true;
          playlists_dir = "/home/dguibert/Music/playlists";
          base_dir = config.role.mopidy-server.configuration.local.media_dir;
          default_extension = ".m3u8";
        };
        role.mopidy-server.configuration.local.scan_follow_symlinks = true;
        role.mopidy-server.configuration.iris.country = "FR";
        role.mopidy-server.configuration.iris.locale = "FR";
      })
      outputs.nixosModules.wayland-conf
      outputs.nixosModules.yubikey-gpg-conf
      ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.desktop) {
        wayland-conf.enable = true;
        yubikey-gpg-conf.enable = true;
      })
      # server-3dprinting
      outputs.nixosModules.server-3Dprinting
      ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.server-3Dprinting) {
        server-3Dprinting.enable = true;
        networking.firewall.interfaces."eth0".allowedTCPPorts = [ 80 ];
      })

      # platypush
      ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.platypush) {
        services.redis.servers."".enable = true;
      })

      # zigbee
      ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.zigbee) {
        role.zigbee.enable = true;
      })
      ];
    }
