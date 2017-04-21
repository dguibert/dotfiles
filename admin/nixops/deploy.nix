{ dguibertHashedPassword ? null
, ...}@args:
{
  network.description = "NixOS Network";
  network.enableRollback = true;

  defaults = { nodes, pkgs, config, ...}: {
    deployment.alwaysActivate = false;

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
        ];
    };

    users.groups.dguibert.gid = 1000;

    # Enable ZeroTierOne
    services.zerotierone.enable = true;

    networking.useNetworkd = true;
    networking.firewall.allowedUDPPorts = [ 9993 ];

  };

  orsine = { pkgs, config, ...}: {
    imports = [ ./orsine/configuration.nix ];
    deployment.targetHost = "10.147.17.123";

  };

  vbox-57nvj72 = { pkgs, config, ...}: {
    imports = [ ./vbox-57nvj72/configuration.nix ];
    #deployment.targetHost = "10.0.2.15";
    deployment.targetHost = "10.147.17.198";
  };
}
