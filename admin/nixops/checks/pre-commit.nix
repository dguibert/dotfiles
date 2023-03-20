{ config, withSystem, inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    checks = {
      pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          nixpkgs-fmt.enable = true;
          prettier.enable = true;
          trailing-whitespace = {
            enable = true;
            name = "trim trailing whitespace";
            entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/trailing-whitespace-fixer";
            types = [ "text" ];
            stages = [ "commit" "push" "manual" ];
          };
          check-merge-conflict = {
            enable = true;
            name = "check for merge conflicts";
            entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/check-merge-conflict";
            types = [ "text" ];
          };
        };
      };
    };
  };
}
