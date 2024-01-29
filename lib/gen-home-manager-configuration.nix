{ lib }:
system: name: { config, lib, inputs, withSystem, self, ... }: {
  options.modules.homes."${name}" = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
  };

  config.modules.homes."${name}" = [ ];

  config.flake.homeConfigurations =
    withSystem system ({ system, pkgs, ... }: {
      "${name}" = inputs.home-manager.lib.homeManagerConfiguration
        {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs pkgs;
            sopsDecrypt_ = pkgs.sopsDecrypt_;
          };
          modules = config.modules.homes."${name}";
        };
    });
}
