inputs:
{ config, lib, ... }:

let
  cfg = config.users.root.home-manager;
in {
  options.users.root.home-manager.enable = lib.mkOption {
    default = true;
    description = "Whether to enable Home-Manager for root";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.root = (import ./home.nix inputs).home;
    home-manager.useGlobalPkgs = true;
    #home-manager.useUserPackages = true;
    home-manager.verbose = true;
  };

}
