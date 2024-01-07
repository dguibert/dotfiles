{ config, lib, ... }:

let
  cfg = config.role.microvm;
in
{
  options.role.microvm.enable = lib.mkOption {
    default = false;
    description = "Whether to enable microvm config";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    # https://astro.github.io/microvm.nix/advanced-network.html
    networking.useNetworkd = true;
    systemd.network.enable = true;

    systemd.network = {
      netdevs."10-microvm".netdevConfig = {
        Kind = "bridge";
        Name = "microvm";
      };
      networks."10-microvm" = {
        matchConfig.Name = "microvm";
        networkConfig = {
          DHCPServer = true;
          IPv6SendRA = true;
        };
        addresses = [{
          addressConfig.Address = "10.0.0.1/24";
        }
          {
            addressConfig.Address = "fd12:3456:789a::1/64";
          }];
        ipv6Prefixes = [{
          ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64";
        }];
        linkConfig.RequiredForOnline = "no";
      };
      networks."11-microvm" = {
        matchConfig.Name = "vm-*";
        # Attach to the bridge that was configured above
        networkConfig.Bridge = "microvm";
      };
    };
    # Allow DHCP server
    networking.firewall.allowedUDPPorts = [ 67 ];

    # provide Internet access with NAT
    networking.nat = {
      enable = true;
      enableIPv6 = true;
      # Change this to the interface with upstream Internet access
      externalInterface = "bond0";
      internalInterfaces = [ "microvm" ];
    };

  };

}
