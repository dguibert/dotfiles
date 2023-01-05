{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/emacs.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;

  nixpkgs.overlays = [
    inputs.nur_dguibert.overlays.cluster
    inputs.nur_dguibert.overlays.store-spartan
  ];
  home.username = "bguibertd";
  home.homeDirectory = "/home_nfs/bguibertd";
  home.stateVersion = "22.11";

  home.sessionVariables.NIX_STATE_DIR = "${pkgs.nixStore}/var/nix";
  home.sessionVariables.NIX_PROFILE = "${pkgs.nixStore}/var/nix/profiles/per-user/${config.home.username}/profile-x86_64";
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
  programs.bash.bashProfileFile = ".bash_profile.x86_64";
  programs.bash.bashrcFile = ".bashrc.x86_64";
  programs.bash.profileFile = ".profile.x86_64";
  programs.bash.bashLogoutFile = ".bash_logout.x86_64";

  home.profileDirectory = lib.mkForce "${config.home.homeDirectory}/.nix-profile-x86_64";

  home.sessionVariablesFileName = "hm-x86_64-session-vars.sh";
  home.sessionVariablesGuardVar = "__HM_X86_64_SESS_VARS_SOURCED";
  home.pathName = "home-manager-x86_64_path";
  home.gcLinkName = "current-home-x86_64";
  home.generationLinkNamePrefix = "home-manager-x86_64";
}
