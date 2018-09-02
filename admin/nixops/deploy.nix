{ dguibertHashedPassword ? null
#, installer ? false
, ...}@args:
let
  pass_ = key: if builtins.extraBuiltins ? pass then builtins.extraBuiltins.pass key else "without-pass";
in
{
  network.description = "NixOS Network";
  network.enableRollback = true;

  defaults = { nodes, pkgs, config, ...}: {
    deployment.alwaysActivate = false;
    deployment.hasFastConnection = true;

    users.mutableUsers = false;

    users.users.dguibert =
#      let
#        dguibertHashedPassword = <dguibertHashedPassword> pkgs.lib.or null;
#      in
    pkgs.lib.mkIf (dguibertHashedPassword != null) {
      isNormalUser = true;
      uid = 1000;
      description = "David Guibert";
      home = "/home/dguibert";
      hashedPassword = dguibertHashedPassword;
      group = "dguibert";
      extraGroups = [ "dguibert" "wheel" "users" "disk" "video" "audio" "adm"
        ] ++ pkgs.lib.optionals (config.users.groups ? vboxusers) [ "vboxusers"
        ] ++ pkgs.lib.optionals (config.users.groups ? docker) [ "docker"
        ] ++ pkgs.lib.optionals (config.users.groups ? libvirtd) [ "libvirtd"
        ] ++ pkgs.lib.optionals (config.users.groups ? disnix) [ "disnix"
        ];
      openssh.authorizedKeys.keys = [
        "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
        "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/ybduCylLGOCgnOdyKZM3rsXr3WnMu9SHSxMV5EY5LkT7Gv1lamNuZbByUY2dPVSgBstYSpbPcmwjYQSqRRuPtgHsRAqvgc2lrGKBKw0tXYgWXFEjXugDMgi9safr86+bbmRhNgU5jzJZ7/BDHDLW5dWMPGK/B6mg9e+E+gZM7Fh99FYn+ys6qB2Ca0tu0jXFLRN5fMe640DI0vjk5lctJikXtfKsyFqiiwjVcqMpVJuCrDpnhp2+uJz/19cjHwjJx8WmLSyYJf0gXlcklgKp781J4D3diLmN9Sz9r22T5WXCiljgsod91eok0rqQxh21DOtGuHXlNkdzjiMHgB/fMAA5NS5ql09cTC4pvL3XQYMbmnGU0gVs25048duwLCs5ISH5kPIsmDUsYU6/O1f7JVboHKNc5EfpGGJnuzUvgLA5ox8tQdHb+DOSp1GSm3JQs6cRzJlW73b/NVPqRqgZVqzC72NkxxdvMrxLE6riajtKW5AU45ZT8hOgNSiQKSxvnc68awni/59aObNEeOJzUo0BqKCB5VLGbK1u6nCrU3l+5U1LXKUDmmokgNOktKRgLkkkXkwfV6o0JKetODZUceN1hfveDpqYZ2Jm43VJrAetUX5AlOqE8z6Ok4RHq79gtBHs5fHEmKW3QeJkau0PDi7BAPSpWy3glZrFTztHgQ== CA key for my accounts at work"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4j+CEKsGc4N/TJ7scLZO6joBjCoEjzalODyoIFvjS6A0bgbvI26KEwt4WCtrMYGn3quni9eQRFn6X/Z9yCxHy8Gugwwj+dHTXEzELABspyyjpgdUphL+2k0eFv7n5/OtWBw3XU/EfXeCAQX7guEdUT4Vavn9fXBIHE46HU+vkgRHib8xrYOwBnQeqEgBkH+qs//0aD1x6X3Wt8W1R+TWM/vjuo/myimYzAxNvdCvlYuWzUNZGMXWmASfnEzTb+W06gtO0ofCaUnlZXmk9Fh9sYSIhEQ4DoyX2Fr3PiaiOE0iQr/kzqrFJ3UrdpHzPp7tehgeaEYOBIXDN6dbAPezJ u0_a81@localhost"
      ];
    };

    users.groups.dguibert.gid = 1000;

    # Enable ZeroTierOne
    services.zerotierone.enable = true;
    services.zerotierone.joinNetworks = [ "e5cd7a9e1cd44c48" ];

    networking.useNetworkd = true;
    services.nscd.enable = false; # no real gain (?) on workstations

    # disnix target
    services.disnix.enable = true;
    dysnomia.properties.mem = "$(grep 'MemTotal:' /proc/meminfo | sed -e 's/kB//' -e 's/MemTotal://' -e 's/ //g')";
    dysnomia.properties.disks = "$(ls /dev/disk/by-id/ | grep -v -- '-part.*' | tr '\\\\n' ' ')";
    # https://hydra.nixos.org/job/disnix/disnix-trunk/tarball/latest/download-by-type/doc/manual/#chap-packages
    environment.variables.PATH = [ "/nix/var/nix/profiles/disnix/default/bin" ];

    # Package ‘openafs-1.6.22.2-4.18.4’ in /home/dguibert/code/nixpkgs/pkgs/servers/openafs/1.6/module.nix:49 is marked as broken, refusing to evaluate.
    nixpkgs.config.allowBroken = true;
  };

  orsine = { pkgs, config, ...}: {
    imports = [ ./orsine/configuration.nix ];
    #deployment.targetHost = "10.147.17.123";
    # disnixos coordinator
    environment.systemPackages = [ pkgs.disnixos pkgs.wireguard-tools ];

    deployment.keys.wireguard_key.text = pass_ "wireguard/orsine";
    deployment.keys.wireguard_key.destDir = "/secrets";

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
  };

  rpi31 = { config, ...}: {
    imports = [ ./rpi31/configuration.nix ];
    #deployment.targetHost = "192.168.1.13";
    deployment.keys.wireguard_key.text = pass_ "wireguard/rpi31";
    deployment.keys.wireguard_key.destDir = "/secrets";
    ### mesh wg0
    #services.babeld.enable = true;
    #services.babeld.interfaces.wg0 = {
    #  type = "tunnel";
    #};
    #systemd.network.networks."41-wg0".address = [ "fe80::cafe:2" ];
  };

  vbox-57nvj72 = { pkgs, config, ...}: {
    imports = [ ./vbox-57nvj72/configuration.nix ];
    #deployment.targetHost = "10.0.2.15";
    deployment.targetHost = "10.147.17.198";
    deployment.keys.wireguard_key.text = pass_ "wireguard/vbox-57nvj72";
    deployment.keys.wireguard_key.destDir = "/secrets";
    ### mesh wg0
    #services.babeld.enable = true;
    #services.babeld.interfaces.wg0 = {
    #  type = "tunnel";
    #};
    #systemd.network.networks."41-wg0".address = [ "fe80::cafe:3" ];
  };

  titan = { pkgs, config, ...}: {
    imports = [ ./titan/configuration.nix ];
    deployment.targetHost = "192.168.1.40";
  };
}
