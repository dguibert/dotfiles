{ config, lib, pkgs, ... }:
let
  cfg = config.roles.wireguard-mesh;

in {
  options = {
    roles.wireguard-mesh = {
      enable = lib.mkOption {
        default = false;
        description = "Enable to be part of this wiregard-mesh network";
        type = lib.types.bool;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireguard-mesh.enable = true;
    networking.wireguard-mesh.peers = {
      rpi31 = {
        ipv4Address = "10.147.27.13/32";
        ipv6Addresses = {
          orsine = "fe80::216:3eff:fe3f:386d/64";
          titan = "fe80::216:3eff:fe20:26f1/64";
          t580 = "fe80::216:3eff:fe57:81ce/64";
          rpi41 = "fe80::216:3eff:fe3d:dd2f/64";
          rpi01 = "fe80::216:3eff:fe6c:435c/64";
        };
        listenPort = 500;
        publicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
        endpoint   = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
        persistentKeepalive = 25;
      };
      orsine = {
        ipv4Address = "10.147.27.128/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe3f:386d/64";
          titan = "fe80::216:3eff:fe20:26f1/64";
          t580 = "fe80::216:3eff:fe57:81ce/64";
          rpi41 = "fe80::216:3eff:fe3d:dd2f/64";
          rpi01 = "fe80::216:3eff:fe6c:435c/64";
        };
        listenPort = 501;
        publicKey  = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
        endpoint   = "192.168.1.32:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
      };
      titan = {
        ipv4Address = "10.147.27.24/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe3f:386d/64";
          orsine = "fe80::216:3eff:fe20:26f1/64";
          t580 = "fe80::216:3eff:fe57:81ce/64";
          rpi41 = "fe80::216:3eff:fe3d:dd2f/64";
          rpi01 = "fe80::216:3eff:fe6c:435c/64";
        };
        listenPort = 503;
        publicKey  = "wJPL+85/cCK53thEzXB9LIrXF9tCVZ8kxK+tDCHaAU0=";
        endpoint   = "192.168.1.24:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
      };
      t580 = {
        ipv4Address = "10.147.27.17/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe57:81ce/64";
          orsine = "fe80::216:3eff:fe3f:386d/64";
          titan = "fe80::216:3eff:fe20:26f1/64";
          rpi41 = "fe80::216:3eff:fe3d:dd2f/64";
          rpi01 = "fe80::216:3eff:fe6c:435c/64";
        };
        listenPort = 504;
        publicKey  = "DSDxA9qtyYKFQVw/+I7uF/74GPt3E7f2QN2KBX+XtCQ=";
        endpoint   = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
      };
      rpi41 = {
        ipv4Address = "10.147.27.14/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe3d:dd2f/64";
          orsine = "fe80::216:3eff:fe3f:386d/64";
          titan = "fe80::216:3eff:fe20:26f1/64";
          t580 = "fe80::216:3eff:fe57:81ce/64";
          rpi01 = "fe80::216:3eff:fe6c:435c/64";
        };
        listenPort = 505;
        publicKey  = "LF3Dgj29b7GVH/klZhwTAqfo2t6PQnpmTaY8IiQARkA=";
        endpoint   = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
        persistentKeepalive = 25;
      };
      rpi01 = {
        ipv4Address = "10.147.27.10/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe6c:435c/64";
          orsine = "fe80::216:3eff:fe3f:386d/64";
          titan = "fe80::216:3eff:fe20:26f1/64";
          t580 = "fe80::216:3eff:fe57:81ce/64";
          rpi41 = "fe80::216:3eff:fe3d:dd2f/64";
        };
        listenPort = 506;
        publicKey  = "v4TlLNu3KiBYu732QYJFkQs/wCbbNW38iShE+qqLV0s=";
      };
    };

    sops.secrets."wireguard_key"          .path = "/persist/etc/wireguard_key";
    networking.wireguard-mesh.privateKeyFile = "${config.sops.secrets."wireguard_key".path}";

    networking.firewall.allowedUDPPorts = [ 500 501 502 503 504 505 506
      6696 /* babeld */
    ];

  };
}
