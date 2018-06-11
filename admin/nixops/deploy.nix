{ dguibertHashedPassword ? null
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
        ];
      openssh.authorizedKeys.keys = [
        "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHj9CvDWTyCZZnIhq7Gq15a/iDZzFYmcTV8MCb+G/KY44j0gVVpOa7U+LL0HqCyx+nKhx83HGpC7rFq62wQOTVHisws68XlvBqU2XswWvAZqGP1gvtV1P3OMMWxUZ2COIKBJ7a1tzbhOdOtNEaLusl5htOqFigyxhGT+ngkDqJC3M4lF2ayjoGxRvAn88t5kL3yftFwOKvBm6ALEXRwYPqCWJ761J2ML8J/VdUa1OjPd3HXS2r4y4QBxh7eopQrlsQ2xWqH8harP8kTjYPcEgWeRpKl/h7Dzkgxw8G3WMJnob1s5kRdI1LlxhxOZMCMJfpmctY4d70LMuDL/I6haB5 user_ca"
        "cert-authority ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGFz6l5s57+UjjX72iTea17I+qfHWPntFrM0rzYbr+fUBZd0SR2dKnz+nSaBhDtCvD5N+YOWwXEK4WvQ0PkT5Qk= bguibertd@genji0"
      ];
    };

    users.groups.dguibert.gid = 1000;

    # Enable ZeroTierOne
    services.zerotierone.enable = true;
    services.zerotierone.joinNetworks = [ "e5cd7a9e1cd44c48" ];

    networking.useNetworkd = true;

  };

  orsine = { pkgs, config, ...}: {
    imports = [ ./orsine/configuration.nix ];
    deployment.targetHost = "10.147.17.123";

  };

  rpi31 = { config, ...}: {
    imports = [ ./rpi31/configuration.nix ];
    deployment.targetHost = "192.168.1.13";

  };

  vbox-57nvj72 = { pkgs, config, ...}: {
    imports = [ ./vbox-57nvj72/configuration.nix ];
    #deployment.targetHost = "10.0.2.15";
    deployment.targetHost = "10.147.17.198";
  };
}
