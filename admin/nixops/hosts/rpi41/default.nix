{ config, lib, inputs, withSystem, self, ... }:
{
  options.modules.hosts.rpi41 = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
  };

  config.modules.hosts.rpi41 = [ ./configuration.nix ];

  config.flake.nixosConfigurations = withSystem "aarch64-linux" ({ system, ... }: {
    rpi41 = inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        pkgs = self.legacyPackages.${system};
        inherit inputs;
      };
      modules = config.modules.hosts.rpi41;
    };
  });
}

