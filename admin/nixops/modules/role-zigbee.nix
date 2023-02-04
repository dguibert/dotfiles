{ config, lib, pkgs, ... }:

let
  cfg = config.role.zigbee;

  girier_js = pkgs.writeText "girier.js" ''
    const tuya = require('zigbee-herdsman-converters/lib/tuya');
    const reporting = require('zigbee-herdsman-converters/lib/reporting');

    module.exports = [
        {
            fingerprint: [
                {modelID: 'TS0001', manufacturerName: '_TZ3000_majwnphg'},
                {modelID: 'TS0001', manufacturerName: '_TZ3000_6axxqqi2'},
                {modelID: 'TS0001', manufacturerName: '_TZ3000_zw7yf6yk'},
            ],
            model: 'JR-ZDS01',
            vendor: 'Girier',
            description: '1 gang mini switch',
            extend: tuya.extend.switch({switchType: true}),
            configure: async (device, coordinatorEndpoint, logger) => {
                await reporting.bind(device.getEndpoint(1), coordinatorEndpoint, ['genOnOff']);
            },
        },
    ];
  '';
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
      frontend = true;
      mqtt.user = "zigbee";
      mqtt.password = "password";
      network_key = "GENERATE";
      #includes = [
      #  config.secrets.zigbee2mqtt.secretFile
      #];
      external_converters = [
        girier_js
      ];
      groups = {
        "1" = {
          friendly_name = "cuisine";
          devices = [
            "0x84fd27fffe523559/1"
            "0xb4e3f9fffe6b6fa2/1"
          ];
        };
        "2" = {
          friendly_name = "salon";
          devices = [
            "0x70b3d52b6001b6dd/1"
            "0x70b3d52b6001b568/1"
          ];
        };
        "3" = {
          friendly_name = "bureau";
          devices = [
            "0x70b3d52b6001b40f/1"
            "0x70b3d52b6001b52e/1"
          ];
        };
      };
    };

    services.mosquitto.enable = true;
    services.mosquitto.listeners = [
      {
        users.zigbee = {
          password = "password";
        };
      }
    ];
  };

}
