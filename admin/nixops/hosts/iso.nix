{ self, config, pkgs, lib, inputs, withSystem, ... }:
let
  inherit (lib) concatMapStrings concatMapStringsSep head;
in
{
  options.modules.hosts.iso = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
  };

  config.modules.hosts.iso = [
    (import "${inputs.nixpkgs.inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
    self.nixosModules.zfs
    ({ config, ... }: { zfs-conf.enable = true; })
    ({ config, lib, pkgs, resources, ... }: {
      nixpkgs.localSystem.system = "x86_64-linux";
    })
    ({ lib, ... }: {
      networking.wireless.interfaces = [ "wlan0" ];
    })
    ({ config, lib, pkgs, ... }: {
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.supportedFilesystems = [ "zfs" ];
      users.extraUsers.root.initialPassword = lib.mkForce "OhPha3gu";
      services.openssh.enable = true;
      services.openssh.startWhenNeeded = true;
      users.users.root.openssh.authorizedKeys.keys = [
        "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
      ];
      # Select internationalisation properties.
      console.font = "Lat2-Terminus16";
      console.keyMap = "fr";
      i18n.defaultLocale = "en_US.UTF-8";
      console.earlySetup = true;

      # Set your time zone.
      time.timeZone = "Europe/Paris";

      environment.systemPackages = [
        pkgs.vim
      ];
    })
  ];

  config.flake.nixosConfigurations = withSystem "x86_64-linux" ({ system, ... }: {
    iso = inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        pkgs = self.legacyPackages.${system};
        inherit inputs;
      };
      modules = config.modules.hosts.iso;
    };
  });
}

