{ config, lib, pkgs, inputs, outputs, ... }:
let
  cfg = config.role.wireguard-mesh;

  readWgPub = file: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile file);
in
{
  imports = [
    outputs.nixosModules.wireguard-mesh
  ];

  options = {
    role.wireguard-mesh = {
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
          # update all with :%s@fe80::216.*/64@\=system('./random-ipv6.py')@gc
          orsine = "fe80::216:3eff:fe22:9021/64";
          titan = "fe80::216:3eff:fe59:c4c4/64";
          t580 = "fe80::216:3eff:fe10:a915/64";
          rpi41 = "fe80::216:3eff:fe6f:cf10/64";
          rpi01 = "fe80::216:3eff:fe77:22f1/64";
          #asus-laptop = "fe80::216:3eff:fe3c:2427/64";
        };
        listenPort = 500;
        publicKey = readWgPub ../hosts/rpi31/wg_key.pub;
        endpoint = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
        persistentKeepalive = 25;
      };
      orsine = {
        ipv4Address = "10.147.27.128/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe49:54c6/64";
          titan = "fe80::216:3eff:fe5d:c3c0/64";
          t580 = "fe80::216:3eff:fe21:0caa/64";
          rpi41 = "fe80::216:3eff:fe0d:c822/64";
          rpi01 = "fe80::216:3eff:fe70:6d0c/64";
          #asus-laptop = "fe80::216:3eff:fe5a:d172/64";
        };
        listenPort = 501;
        publicKey = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
        endpoint = "192.168.1.32:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
      };
      titan = {
        ipv4Address = "10.147.27.24/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe4b:303e/64";
          orsine = "fe80::216:3eff:fe31:6e39/64";
          t580 = "fe80::216:3eff:fe4e:cb1c/64";
          rpi41 = "fe80::216:3eff:fe24:4ee4/64";
          rpi01 = "fe80::216:3eff:fe39:f05b/64";
          #asus-laptop = "fe80::216:3eff:fe06:1aaf/64";
        };
        listenPort = 503;
        publicKey = readWgPub ../hosts/titan/wg_key.pub;
        endpoint = "192.168.1.24:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
      };
      t580 = {
        ipv4Address = "10.147.27.17/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe57:d94f/64";
          orsine = "fe80::216:3eff:fe67:2f45/64";
          titan = "fe80::216:3eff:fe53:753e/64";
          rpi41 = "fe80::216:3eff:fe09:f8e5/64";
          rpi01 = "fe80::216:3eff:fe5f:aa48/64";
          #asus-laptop = "fe80::216:3eff:fe6a:64a5/64";
        };
        listenPort = 504;
        publicKey = readWgPub ../hosts/t580/wg_key.pub;
        endpoint = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
      };
      rpi41 = {
        ipv4Address = "10.147.27.14/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe49:ea2b/64";
          orsine = "fe80::216:3eff:fe32:c0db/64";
          titan = "fe80::216:3eff:fe25:8bd5/64";
          t580 = "fe80::216:3eff:fe54:7b14/64";
          rpi01 = "fe80::216:3eff:fe0b:6b03/64";
          #asus-laptop = "fe80::216:3eff:fe48:51ce/64";
        };
        listenPort = 505;
        publicKey = readWgPub ../hosts/rpi41/wg_key.pub;
        endpoint = "192.168.1.14:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
        persistentKeepalive = 25;
      };
      rpi01 = {
        ipv4Address = "10.147.27.10/32";
        ipv6Addresses = {
          rpi31 = "fe80::216:3eff:fe7f:91bf/64";
          orsine = "fe80::216:3eff:fe13:3d58/64";
          titan = "fe80::216:3eff:fe68:c921/64";
          t580 = "fe80::216:3eff:fe6f:5221/64";
          rpi41 = "fe80::216:3eff:fe72:4bea/64";
          #asus-laptop = "fe80::216:3eff:fe04:fd86/64";
        };
        listenPort = 506;
        publicKey = "v4TlLNu3KiBYu732QYJFkQs/wCbbNW38iShE+qqLV0s=";
      };
      #asus-laptop = {
      #  ipv4Address = "10.147.27.154/32";
      #  ipv6Addresses = {
      #    rpi31 = "fe80::216:3eff:fe5e:3af7/64";
      #    orsine = "fe80::216:3eff:fe59:9b80/64";
      #    titan = "fe80::216:3eff:fe1b:abdb/64";
      #    t580 = "fe80::216:3eff:fe2f:a16c/64";
      #    rpi41 = "fe80::216:3eff:fe4e:4e97/64";
      #  };
      #  listenPort = 507;
      #  publicKey  = "WoGmHJwHdx2Ormt07CgQ5mK8jU1wMDOSqUli14VzqwI=";
      #};
    };

    sops.secrets."wireguard_key"          .path = "/persist/etc/wireguard_key";
    networking.wireguard-mesh.privateKeyFile = "${config.sops.secrets."wireguard_key".path}";

    networking.firewall.allowedUDPPorts = [
      500
      501
      502
      503
      504
      505
      506
      507
      6696 /* babeld */
    ];

  };
}
