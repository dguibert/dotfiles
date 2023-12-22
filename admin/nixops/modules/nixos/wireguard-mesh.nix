{ config, lib, pkgs, ... }:

with lib;

let
  random-ipv6-script = pkgs.writeScript "ramdom-ipv6.py" ''
    #!${pkgs.python3}/bin/python
    # https://blog.fugoes.xyz/2018/02/03/Run-Babeld-over-Wireguard.html
    import random

    def random_mac():
        digits = [0x00, 0x16, 0x3e, random.randint(0x00, 0x7f), random.randint(0x00, 0xff), random.randint(0x00, 0xff)]
        return ":".join(map(lambda x: "%02x" % x, digits))

    def mac_to_ipv6(mac):
        parts = mac.split(":")
        parts.insert(3, "ff")
        parts.insert(4, "fe")
        parts[0] = "%x" % (int(parts[0], 16) ^ 2)
        ipv6_parts = []
        for i in range(0, len(parts), 2):
            ipv6_parts.append("".join(parts[i:i + 2]))
        return "fe80::%s/64" % (":".join(ipv6_parts))

    def random_ipv6():
        return mac_to_ipv6(random_mac())

    if __name__ == "__main__":
        print(random_ipv6(), end="")
  '';
  # runCommandNoCC name: env: buildCommand:
  random-ipv6 = name: builtins.readFile (toString
    (pkgs.runCommandNoCC "ipv6-${name}" { } ''
      mkdir $out
      ${random-ipv6-script} > $out/ipv6
    '') + "/ipv6");

  cfg = config.networking.wireguard-mesh;

  peerNames = builtins.filter (n: n != config.networking.hostName) (builtins.attrNames cfg.peers);
in
{
  options = {
    networking.wireguard-mesh = {
      enable = mkEnableOption "Enable a wireguard mesh network";
      ipv4Address = mkOption {
        type = types.str;
      };
      privateKeyFile = mkOption {
        default = toString "/secrets/wireguard_key";
      };
      peers = mkOption {
        default = { };
        #type = with types; loaOf (submodule peerOpts);
        example = { };
        description = ''
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # https://www.sweharris.org/post/2016-10-30-ssh-certs/
    # http://www.lorier.net/docs/ssh-ca
    # https://linux-audit.com/granting-temporary-access-to-servers-using-signed-ssh-keys/
    environment.systemPackages = [ pkgs.wireguard-tools ];
    systemd.network.netdevs = listToAttrs (flip map peerNames
      (n:
        let
          peer = builtins.getAttr n cfg.peers;
        in
        nameValuePair "50-${n}" {
          netdevConfig.Kind = "wireguard";
          netdevConfig.Name = "${n}";
          netdevConfig.MTUBytes = "1300";

          wireguardConfig.PrivateKeyFile = cfg.privateKeyFile;
          wireguardConfig.ListenPort = peer.listenPort;

          wireguardPeers = [
            {
              wireguardPeerConfig = {
                PublicKey = peer.publicKey;
                AllowedIPs = [
                  "0.0.0.0/0"
                  #"ff02::/16"
                  "::/0"
                  # The Babel protocol uses IPv6 link-local unicast and multicast addresses
                  "fe80::/64"
                  "ff02::1:6/128"
                ];
                Endpoint = mkIf (peer ? endpoint) peer.endpoint;
                PersistentKeepalive = peer.persistentKeepalive or 0;
              };
            }
          ];
        }));
    systemd.network.networks = listToAttrs (flip map peerNames
      (n:
        let
          peer = builtins.getAttr n cfg.peers;
        in
        nameValuePair "${n}" {
          matchConfig.Name = "${n}";
          address = [
            cfg.peers."${config.networking.hostName}".ipv4Address
            # Assign an IPv6 link local address on the tunnel so multicast works
            cfg.peers."${config.networking.hostName}".ipv6Addresses.${n}
          ];
          DHCP = "no";
          networkConfig = {
            IPMasquerade = "ipv4";
            IPForward = true;
          };
        }));

    services.babeld.enable = true;
    services.babeld.interfaceDefaults = {
      type = "tunnel";
      "split-horizon" = true;
    };
    # https://www.kepstin.ca/blog/babel-routing-over-wireguard-for-the-tubes/
    services.babeld.extraConfig = ''
      ${concatMapStrings (n: ''
        interface ${n}
      '') peerNames}
      skip-kernel-setup true
      # Prefer using unicast messages over the tunnel
      default unicast true
      # mesh IPv4
      redistribute local ip 10.147.27.0/24 metric 128
      redistribute ip 10.147.27.0/24 ge 13 metric 128
      ## refuse anything else not explicitely allowed
      redistribute local deny
      redistribute deny
    '';
    systemd.services.babeld = {
      serviceConfig = {
        #IPAddressAllow = [ "fe80::/64" "ff00::/8" "::1/128" "127.0.0.0/8" "10.147.27.0/24" ];
        IPAddressAllow = [ "10.147.27.0/24" ];
        RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];
      };
    };

    networking.firewall.allowedUDPPorts = [ 6696 ];
  };
}


