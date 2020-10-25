{ config, lib, ... }:

let
  cfg = config.empty;
in {
  options.empty.enable = lib.mkOption {
    default = true;
    description = "Whether to enable empty";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
  };

}
