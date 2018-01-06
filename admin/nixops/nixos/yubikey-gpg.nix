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

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];
}
