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
        #type = types.attrsOf types.raw;
        default = { };
        description = ''
          Instantiated Home-Manager configurations. Used by `home-rebiuld`.

          `homeConfigurations` is for specific user homes. If you want to expose
          reusable configurations, add them to [`hmModules`](#opt-flake.hmModules)
          in the form of modules (no `lib.homeManagerConfiguration`), so that you can reference
          them in this or another flake's `homeManagerConfiguration`.
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
