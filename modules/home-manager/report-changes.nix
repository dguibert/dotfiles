{ pkgs, activationPkgs, config, lib, ... }:
with lib;
{
  options.home.report-changes.enable = mkEnableOption "report-changes";
  config = mkIf config.home.report-changes.enable {
    home.activation.report-changes = config.lib.dag.entryAnywhere ''
      echo "Diffing: $oldGenPath $newGenPath"
      ${activationPkgs.nix}/bin/nix store diff-closures $oldGenPath $newGenPath || true
    '';
  };
}

