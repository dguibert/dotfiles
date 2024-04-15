{ lib, config, pkgs, inputs, ... }:
{
  options.withZellij.enable = (lib.mkEnableOption "Enable Zellij config"); # // { default = true; };

  config = lib.mkIf config.withZellij.enable {
    programs.zellij.enable = true;

    programs.zellij.settings = {
      keybinds = {
        unbind = "Ctrl q"; # unbind in all modes

        locked = {
          unbind = "Ctrl g";
          bind = {
            _args = [ "Alt g" ];
            SwitchToMode = "normal";
          };
        };
      };

      # default_layout "compact"
      default_mode = "locked";
      copy_command = "wl-copy";
      pane_frames = false;
      # copy_clipboard "primary"

      pane = {
        _args = [
          "size = 1"
          "borderless = true"
        ];
        plugin = {
          _props = { location = "zellij:compact-bar"; };
        };
      };
    };
  };
}
