{ dguibertHashedPassword ? null
, installer ? false
, ...}@args:
{
  network.description = "NixOS Network";
  network.enableRollback = true;

  defaults = { nodes, pkgs, config, ...}: {
    deployment.alwaysActivate = false;
    deployment.hasFastConnection = true;

    users.mutableUsers = false;

    users.users.dguibert = pkgs.lib.mkIf (dguibertHashedPassword != null) {
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
    services.dysnomia.properties.mem = "$(grep 'MemTotal:' /proc/meminfo | sed -e 's/kB//' -e 's/MemTotal://' -e 's/ //g')";
    services.dysnomia.properties.disks = "$(ls /dev/disk/by-id/ | grep -v -- '-part.*' | tr '\\\\n' ' ')";
    # https://hydra.nixos.org/job/disnix/disnix-trunk/tarball/latest/download-by-type/doc/manual/#chap-packages
    environment.variables.PATH = [ "/nix/var/nix/profiles/disnix/default/bin" ];
  };

  orsine = { pkgs, config, ...}: {
    imports = [ ./orsine/configuration.nix ];
    deployment.targetHost = "10.147.17.123";
    # disnixos coordinator
    environment.systemPackages = [ pkgs.disnixos ];

    deployment.keys.wireguard_key.text = builtins.extraBuiltins.pass "wireguard/orsine";
    deployment.keys.wireguard_key.destDir = "/secrets";
  };

  rpi31 = { config, ...}: {
    imports = [ ./rpi31/configuration.nix ];
    deployment.targetHost = "192.168.1.13";
    deployment.keys.wireguard_key.text = builtins.extraBuiltins.pass "wireguard/rpi31";
    deployment.keys.wireguard_key.destDir = "/secrets";
  };

  vbox-57nvj72 = { pkgs, config, ...}: {
    imports = [ ./vbox-57nvj72/configuration.nix ];
    #deployment.targetHost = "10.0.2.15";
    deployment.targetHost = "10.147.17.198";
    # disnixos coordinator
    environment.systemPackages = [ pkgs.disnixos ];
    deployment.keys.wireguard_key.text = builtins.extraBuiltins.pass "wireguard/vbox-57nvj72";
    deployment.keys.wireguard_key.destDir = "/secrets";
  };

  titan = { pkgs, config, ...}: {
    imports = [ ./titan/configuration.nix ];
    deployment.targetHost = "192.168.1.40";
  };
}
