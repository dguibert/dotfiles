{ config, lib, ... }:
let
  cfg = config.roles.sshguard;
in
{
  options.roles.sshguard.enable = lib.mkOption {
    default = true;
    description = "Wether to enable sshguard role";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    services.sshguard = {
      enable = true;
      blacklist_file = "/persist/var/lib/sshgaurd/blacklist.db";
      whitelist = [
        "192.168.1.24"
        "10.146.27.0/24"
        "2.6.193.170/32"
      ];
    };

    # to prevent multiple authentication attempts during a single connection
    services.openssh.extraConfig = ''
      MaxAuthTries 5
    '';
  };
}
