{ config, lib, pkgs, outputs, ... }: {
  nixpkgs.localSystem = {
    #gcc.arch = "skylake"; #kabylake
    #gcc.tune = "skylake"; #kabylake
    system = "x86_64-linux";
  };
  imports = [
    (import ./configuration.nix)
    outputs.nixosModules.defaults
    outputs.nixosModules.yubikey-gpg-conf
    ({ config, ... }: { yubikey-gpg-conf.enable = true; })
    outputs.nixosModules.x11-conf
    ({ config, ... }: { x11-conf.enable = false; })

    outputs.nixosModules.wayland-conf
    ({ config, ... }: { wayland-conf.enable = true; })
  ];
  sops.defaultSopsFile = ./secrets/secrets.yaml;
}
