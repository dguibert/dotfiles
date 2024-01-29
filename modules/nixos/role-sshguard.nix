{ config, lib, ... }:
let
  cfg = config.role.sshguard;
in
{
  options.role.sshguard.enable = lib.mkOption {
    default = true;
    description = "Wether to enable sshguard role";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    services.sshguard = {
      enable = true;
      blacklist_file = "/persist/var/lib/sshguard/blacklist.db";
      whitelist = [
        "192.168.1.24"
        "10.147.27.0/24"
      ];
    };
    systemd.tmpfiles.rules = [ "d /persist/var/lib/sshguard 1770 root root -" ];

    # to prevent multiple authentication attempts during a single connection
    services.openssh.extraConfig = ''
      MaxAuthTries 5
    '';
  };
}
