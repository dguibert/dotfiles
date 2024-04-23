{ lib }:
system: name: { config, lib, inputs, withSystem, self, ... }: {
  options.modules.homes."${name}" = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
  };

  options.modules.homes."${name}-cross-system" = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
  };

  config.modules.homes."${name}" = [ ];

  config.flake.homeConfigurations =
    withSystem system ({ system, pkgs, ... }:
      let
        pkgs' =
          if config.modules.homes."${name}-cross-system" != null then
            pkgs.pkgsCross.${config.modules.homes."${name}-cross-system"} else pkgs;
      in
      {
        "${name}" = inputs.home-manager.lib.homeManagerConfiguration
          {
            pkgs = pkgs';
            extraSpecialArgs = {
              inherit inputs;
              pkgs = pkgs';
              sopsDecrypt_ = pkgs.sopsDecrypt_;
            };
            modules = config.modules.homes."${name}";
          };
      });
}
