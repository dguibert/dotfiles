# https://rzetterberg.github.io/yubikey-gpg-nixos.html
{ config, lib, pkgs, ... }:

{
  programs.ssh.startAgent = false;

  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    gnupg
    yubikey-personalization
    yubico-piv-tool
  ];

  #environment.shellInit = ''
  #if [ -z "$SSH_CLIENT" ]; then
  #  #export GPG_AGENT_SOCK=$XDG_RUNTIME_DIR/gnupg/S.gpg-agent
  #  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  #	gpg-connect-agent /bye
  #fi
  #'';

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];
}
