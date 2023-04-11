{ lib, config, pkgs, inputs, outputs, ... }:
{
  imports = [
    ./dguibert/home.nix
    ./dguibert/custom-profile.nix
  ];
  centralMailHost.enable = false;
  withGui.enable = false;
  withEmacs.enable = false;
  withCustomProfile.enable = true;
  withCustomProfile.suffix = "";

  home.username = "dguibert";
  home.homeDirectory = "/users/dguibert";
  home.stateVersion = "22.11";
  #home.activation.setNixVariables = lib.hm.dag.entryBefore ["writeBoundary"]
  home.sessionPath = [
    "${pkgs.nix}/bin"
  ];

  programs.bash.bashrcExtra = ''
    export NIX_IGNORE_SYMLINK_STORE=1
  '';
  home.sessionVariables.NIX_IGNORE_SYMLINK_STORE = 1;

  # additional programs
  home.packages = with pkgs;
    [
      xpra
      bashInteractive

      datalad
      git-annex

      git-nomad
    ];
}
