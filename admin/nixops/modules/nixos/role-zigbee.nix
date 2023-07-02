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
    systemd.services.zigbee2mqtt.unitConfig.ConditionPathExists = "/dev/ttyACM0";
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
      availability = {
        active.timeout = 10;
        passive.timeout = 10;
      };
      channel = 26; # https://haade.fr/fr/blog/interference-zigbee-wifi-2-4ghz-a-savoir
    };

    services.mosquitto.enable = true;
    services.mosquitto.listeners = [
      {
        users.zigbee = {
          acl = [
            "readwrite #"
          ];
          # nix shell nixpkgs#mosquitto --command mosquitto_passwd -c /tmp/password zigbee
          password = "$7$101$hjkpxbnBRKvg9ZdL$wlF214j+mWx17ccKDapsnBzcfsZiDGkM9f/ugKOw7GAwYttG+mdtWVpkakB6mee0i7lJl102lnmu48BoVKpfmg==";
        };
        users.root = {
          acl = [
            "readwrite #"
          ];
          # nix shell nixpkgs#mosquitto --command mosquitto_passwd -c /tmp/password root
          password = "$7$101$hjkpxbnBRKvg9ZdL$wlF214j+mWx17ccKDapsnBzcfsZiDGkM9f/ugKOw7GAwYttG+mdtWVpkakB6mee0i7lJl102lnmu48BoVKpfmg==";
        };
      }
    ];
  };

}
