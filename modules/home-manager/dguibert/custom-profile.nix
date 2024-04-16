{ lib, config, pkgs, inputs, ... }:
let
  name = config.withCustomProfile.suffix;
  dot_suffix = if name != "" then ".${name}" else "";
  dash_suffix = if name != "" then "-${name}" else "";
  dash_suffix_ = if name != "" then "-${name}_" else "-";
  upper_suffix = lib.toUpper "${name}_";
in
{
  options.withCustomProfile.enable = (lib.mkEnableOption "Enable custom profile") // { default = false; };
  options.withCustomProfile.suffix = lib.mkOption {
    default = "";
    description = "Profile prefix";
    type = lib.types.str;
  };

  config = lib.mkIf config.withCustomProfile.enable {
    home.sessionVariables.NIX_STATE_DIR = "${builtins.dirOf builtins.storeDir}/var/nix";
    home.sessionVariables.NIX_PROFILE = "${builtins.dirOf builtins.storeDir}/var/nix/profiles/per-user/${config.home.username}/profile${dash_suffix}";
    programs.bash.bashrcExtra = /*(homes.withoutX11 args).programs.bash.initExtra +*/ ''
      export NIX_STATE_DIR=${config.home.sessionVariables.NIX_STATE_DIR}
      export NIX_PROFILE=${config.home.sessionVariables.NIX_PROFILE}
      export PATH=$NIX_PROFILE/bin:$PATH:${pkgs.nix}/bin
    '';
    home.activation.setNixVariables = lib.hm.dag.entryBefore [ "writeBoundary" "checkLinkTargets" "checkFilesChanges" ]
      ''
        set -x
        export NIX_STATE_DIR=${config.home.sessionVariables.NIX_STATE_DIR}
        export NIX_PROFILE=${config.home.sessionVariables.NIX_PROFILE}
        export PATH=${pkgs.nix}/bin:$PATH
        rm -rf ${config.home.profileDirectory}
        ln -sf ${config.home.sessionVariables.NIX_PROFILE} ${config.home.profileDirectory}
        export HOME_MANAGER_BACKUP_EXT=bak
        nix-env --set-flag priority 80 nix || true
        set +x
      '';
    # [[ -f ~/.profile.$(uname -m) ]] && . ~/.profile.$(uname -m)
    programs.bash.bashProfileFile = ".bash_profile${dot_suffix}";
    programs.bash.bashrcFile = ".bashrc${dot_suffix}";
    programs.bash.profileFile = ".profile${dot_suffix}";
    programs.bash.bashLogoutFile = ".bash_logout${dot_suffix}";

    home.profileDirectory = lib.mkForce "${config.home.homeDirectory}/.nix-profile${dash_suffix}";

    home.sessionVariablesFileName = "hm${dash_suffix}session-vars.sh";
    home.sessionVariablesGuardVar = "__HM_${upper_suffix}SESS_VARS_SOURCED";
    home.pathName = "home-manager${dash_suffix_}path";
    home.gcLinkName = "current-home${dash_suffix}";
    home.generationLinkNamePrefix = "home-manager${dash_suffix}";
  };

}
