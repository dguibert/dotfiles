{ pkgs, config, lib, ... }:
with lib;
{
  options.report-changes.enable = mkEnableOption "report-changes";
  config = mkIf config.report-changes.enable {
    system.activationScripts.nvd = ''
      ${pkgs.nvd}/bin/nvd $oldGenPath $newGenPath
    '';
  };
}

