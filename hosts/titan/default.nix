{ config, lib, inputs, withSystem, self, ... }:
{
  options.modules.hosts.titan = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ./titan.nix ];
  };

  config.modules.hosts.titan = [ ./titan.nix ];

  config.flake.nixosConfigurations = withSystem "x86_64-linux" ({ system, ... }: {
    titan = inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        pkgs = self.legacyPackages.${system};
        inherit inputs;
      };
      modules = config.modules.hosts.titan;
    };
  });
}

