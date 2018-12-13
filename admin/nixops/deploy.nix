{ dguibertHashedPassword ? null
#, installer ? false
, ...}@args:
let
  pass_ = key: if builtins ? extraBuiltins then 
                 if builtins.extraBuiltins ? pass then builtins.extraBuiltins.pass key
                 else "without-pass"
                 else if builtins ? exec then builtins.exec [ "${toString ./nix-pass.sh}" "${key}" ] else "without-pass";
in
{
  network.description = "NixOS Network";
  network.enableRollback = true;

  orsine = { pkgs, config, lib, ...}: {
    imports = [ ./config/orsine/configuration.nix 
    ];
    #deployment.targetHost = "10.147.17.123";

    #################################################################
    # Test raw networkd wireguard support
    # boot.extraModulePackages = [ pkgs.linuxPackages.wireguard ];
    #environment.systemPackages = [ pkgs.wireguard-tools ];
    #deployment.keys."41-wg1-k.netdev".text = if builtins.extraBuiltins ? pass then builtins.extraBuiltins.pass "wireguard/orsine-netdev" else "";
    #deployment.keys."41-wg1-k.netdev".destDir = "/etc/systemd/network/";

    ## after 40-*, before 99-main
    #systemd.network.netdevs."41-wg1" = {
    #  netdevConfig.Name = "wg1";
    #  netdevConfig.Kind = "wireguard";

    #  wireguardConfig.PrivateKey = "ADGL+IMKmoAcBl8vRy1re0JuYSiKZWueQAhzEw3ijXw=";
    #  wireguardPeers = [
    #    { wireguardPeerConfig = {
    #          AllowedIPs = [ "10.147.27.0/24" "fe80::/64" ];
    #          PublicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
    #          Endpoint   = "83.155.85.77:500";
    #    }; }
    #  ];
    #};
    #systemd.network.networks."41-wg1" = {
    #  networkConfig.Description="my Home VPN based on WireGuard";
    #  matchConfig.Name="wg1";
    #  address = [ "10.147.27.123/24" ];
    #};
    #[Service]
    #Type=oneshot
    #ExecStart=/bin/bash -c "/bin/echo 'br0 available, setting MAC ' `/bin/cat /sys/class/net/wlan0/address`"
    #ExecStart=/bin/bash -c "/sbin/ip link set br0 address `/bin/cat /sys/class/net/wlan0/address`"
    #
    #[Install]
    #WantedBy=sys-subsystem-net-devices-br0.device
    # sys-subsystem-net-devices-wg1.device
    #################################################################
    #################################################################
    ### mesh wg0
    #services.babeld.enable = true;
    #services.babeld.interfaces.wg0 = {
    #  type = "tunnel";
    #};
    #systemd.network.networks."41-wg0".address = [ "fe80::cafe:1" ];
    # ip -6 addr add $(ahcp-generate-address fe80::) dev wg1
    #services.babeld.extraConfig = ''
    #redistribute local if <interface> deny
    #'';
    #home-manager.users.dguibert = import ~/.config/nixpkgs/home.nix { inherit pkgs lib; };
  };

  rpi31 = { pkgs, config, lib, ...}: {
    imports = [ ./config/rpi31/configuration.nix ];
  };

  vbox-57nvj72 = { pkgs, config, lib, ...}: {
    imports = [ ./config/vbox-57nvj72/configuration.nix
    ];
    #deployment.targetHost = "10.0.2.15";
    deployment.targetHost = "10.147.17.198";
    #home-manager.users.dguibert = import ~/.config/nixpkgs/home.nix { inherit pkgs lib; };
  };

  titan = { pkgs, config, lib, ...}: {
    imports = [ ./config/titan/configuration.nix 
    ];
  };
}
