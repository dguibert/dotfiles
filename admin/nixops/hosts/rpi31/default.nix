{ config, lib, pkgs, outputs, inputs, ... }: {
  #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
  #nixpkgs.localSystem.system = "x86_64-linux";
  nixpkgs.localSystem.system = "aarch64-linux";
  imports = [
    (import "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
    (import ./configuration.nix)
    outputs.nixosModules.defaults
  ];
  nixpkgs.overlays = [
    inputs.nix.overlays.default
    inputs.nur_dguibert.overlays.default
    (final: prev: {
      # don't build qt5
      # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
      pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
    })
  ];

  documentation.nixos.enable = false;
  #fileSystems."/".options = [ "defaults" "discard" ];
  services.fstrim.enable = true;

  programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";
  #assertions = lib.singleton {
  #  assertion = pkgs.stdenv.system == "aarch64-linux";
  #  message = "rpi31-configuration.nix can be only built natively on Aarch64 / ARM64; " +
  #    "it cannot be cross compiled";
  #};
  services.openssh.extraConfig = ''
    Match Group sftponly
    ChrootDirectory %h
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication no
  '';
  #  echo -n "ss://"`echo -n chacha20-ietf-poly1305:$(sops --extract '["shadowsocks"]' -d hosts/rpi31/secrets/secrets.yaml)@$(curl -4 ifconfig.io):443 | base64` | qrencode -t UTF8
  sops.secrets.shadowsocks = { };
  sops.defaultSopsFile = ./secrets/secrets.yaml;
}
