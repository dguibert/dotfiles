{ pkgs, config, lib, ... }:
with lib;
{
  options.report-changes.enable = mkEnableOption "report-changes";
  config = mkIf config.report-changes.enable {
    system.activationScripts.nvd = ''
      echo "Diffing: $(readlink /run/current-system) $systemConfig"
      ${config.nix.package}/bin/nix store diff-closures /run/current-system $systemConfig || true
    '';
  };
}




