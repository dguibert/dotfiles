{ config, lib, inputs, withSystem, self, ... }:
{
  options.modules.hosts.t580 = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
  };

  config.modules.hosts.t580 = [ ./configuration.nix ];

  config.flake.nixosConfigurations = withSystem "x86_64-linux" ({ system, ... }: {
    t580 = inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        pkgs = self.legacyPackages.${system};
        inherit inputs;
      };
      modules = config.modules.hosts.t580;
    };
  });
}

