{ config, lib, ... }:

let
  cfg = config.role-otp-authentication;
in
{
  options.role-otp-authentication.enable = lib.mkOption {
    default = false;
    description = "Whether to enable OATH PAM authentication";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    security.pam.oath.enable = false;
    security.pam.services.sshd = { oathAuth = true; };
    security.pam.oath.usersFile = config.sops.secrets."oath-users-file".path;

    sops.secrets.oath-users-file = {
      sopsFile = ../secrets/defaults.yaml;
      owner = "root";
      mode = "600";
      path = "/etc/users.oath";
    };

    ## https://wiki.archlinux.org/title/Pam_oath
    services.openssh.passwordAuthentication = lib.mkForce true;
    services.openssh.extraConfig = ''
      ChallengeResponseAuthentication yes
    '';
  };

}
