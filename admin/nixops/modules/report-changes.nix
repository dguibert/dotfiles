{ pkgs, config, lib, ... }:
with lib;
{
  options.report-changes.enable = mkEnableOption "report-changes";
  config = mkIf config.report-changes.enable {
    system.activationScripts.nvd = ''
      echo "Diffing: $(readlink /run/current-system) $systemConfig"
      (
      export PATH=${pkgs.nix}/bin:$PATH
      ${pkgs.nvd}/bin/nvd /run/current-system $systemConfig
      )
    '';
  };
}




