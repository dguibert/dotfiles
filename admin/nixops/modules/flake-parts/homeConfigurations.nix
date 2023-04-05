{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    literalExpression
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      homeConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = ''
          Instantiated Home-Manager configurations. Used by `home-rebiuld`.

          `homeConfigurations` is for specific user homes. If you want to expose
          reusable configurations, add them to [`nixosModules`](#opt-flake.nixosModules)
          in the form of modules (no `lib.nixosSystem`), so that you can reference
          them in this or another flake's `nixosConfigurations`.
        '';
        example = literalExpression ''
          {
            my-home = inputs.home-manager.lib.homeManagerConfiguration {
              modules = [
                ./my-home/user-configuration.nix
              ];
            };
          }
        '';
      };
    };
  };
}
