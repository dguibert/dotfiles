{ config, lib, ... }:

let
  cfg = config.empty;
in
{
  options.role-sftponly.enable = lib.mkOption {
    default = false;
    description = "Whether to enable empty";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    services.openssh.extraConfig = ''
      Match Group sftponly
      ChrootDirectory %h
      ForceCommand internal-sftp
      AllowTcpForwarding no
      X11Forwarding no
      PasswordAuthentication no
    '';
  };

}
