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
    inputs.nur_dguibert.overlays.spartan
  ];
  home.username = "bguibertd";
  home.homeDirectory = "/home_nfs/bguibertd";
  home.stateVersion = "22.11";
  #home.activation.setNixVariables = lib.hm.dag.entryBefore ["writeBoundary"]
  home.sessionVariables.NIX_STATE_DIR = "${pkgs.nixStore}/var/nix";
  home.sessionVariables.NIX_PROFILE = "${config.home.profileDirectory}";
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
      rm -rf $HOME/.nix-profile
      ln -sf ${outputs.deploy.nodes.spartan.profiles.bguibertd.profilePath} $NIX_PROFILE
      export HOME_MANAGER_BACKUP_EXT=bak
      nix-env --set-flag priority 80 nix || true
      set +x
    '';
  home.sessionPath = [
    "${pkgs.nix}/bin"
  ];

  home.packages = with pkgs; [
    xpra
    bashInteractive

    datalad
    git-annex
  ];
}
