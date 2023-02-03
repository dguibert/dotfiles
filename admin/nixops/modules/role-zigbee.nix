{ config, lib, ... }:

let
  cfg = config.role.zigbee;
in
{
  options.role.zigbee.enable = lib.mkOption {
    default = false;
    description = "Whether to enable zigbee";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    services.zigbee2mqtt.enable = true;
    services.zigbee2mqtt.settings = {
      permit_join = true;
      serial.port = "/dev/ttyACM0";
    };
  };

}
