{ lib, config, pkgs, inputs, ... }:
{
  options.withZellij.enable = (lib.mkEnableOption "Enable Zellij config"); # // { default = true; };

  config = lib.mkIf config.withZellij.enable {
    home.packages = with pkgs; [
      zellij
    ];
    # .config/zellij/config.kdl
  };
}
