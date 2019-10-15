
{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  # git(+http|+https|+ssh|+git|+file|):(//<server>)?<path>(\?<params>)?
  # git+file:///home/my-user/some-repo/some-repo
  # ref, rev, dir
  inputs = {
    nixpkgs.uri = "github:dguibert/nixpkgs/pu";
    #nur_dguibert.uri = "github:dguibert/nur-packages/pu";
    nur_dguibert.uri = "/home/dguibert/nur-packages";
    #"nixos-18.03".uri = "github:nixos/nixpkgs-channels/nixos-18.03";
    #"nixos-18.09".uri = "github:nixos/nixpkgs-channels/nixos-18.09";
    #"nixos-19.03".uri = "github:nixos/nixpkgs-channels/nixos-19.03";
    "base16-nix" = { uri  = "github:atpotts/base16-nix"; flake=false; };
    NUR = { uri  = "github:nix-community/NUR"; flake=false; };
    gitignore = { uri  = "github:hercules-ci/gitignore"; flake=false; };
    #home-manager.uri = /home/dguibert/code/home-manager;
  };

  outputs = { self, nixpkgs, nur_dguibert, base16-nix, ... }: let
    pkgs = import "${nur_dguibert}/pkgs.nix" {
      inherit nixpkgs;
      localSystem = { system = "x86_64-linux"; };# FIXME hard coded for now
    };
    in rec {

    ## - packages: A set of derivations used as a default by most nix commands. For example, nix run nixpkgs:hello uses the packages.hello attribute of the nixpkgs flake. It cannot contain any non-derivation attributes. This also means it cannot be a nested set! (The rationale is that supporting nested sets requires Nix to evaluate each attribute in the set, just to discover which packages are provided.)
    #packages.hello = nixpkgs.provides.packages.hello;
    packages = {
      inherit (pkgs) hello nix;
    };

    ## - defaultPackage: A derivation used as a default by most nix commands if no attribute is specified. For example, nix run dwarffs uses the defaultPackage attribute of the dwarffs flake.
    ##
    ## - checks: A non-nested set of derivations built by the nix flake check command, and by Hydra if a flake does not have a hydraJobs attribute.
    checks.hello = packages.hello;
    ##
    ## - hydraJobs: A nested set of derivations built by Hydra.
    ##
    ## - devShell: A derivation that defines the shell environment used by nix dev-shell if no specific attribute is given. If it does not exist, then nix dev-shell will use defaultPackage.
    devShell = with pkgs; mkEnv {
      name = "nix";
      buildInputs = [ nixFlakes jq ];
      shellHook = ''
        unset NIX_INDENT_MAKE
        unset IN_NIX_SHELL
        unset TMP TMPDIR

        ## https://blog.wearewizards.io/how-to-use-nixops-in-a-team
        #export GIT_DIR=$HOME/.mgit/dotfiles/.git
        #export NIXOPS_STATE=secrets/deploy.nixops

        #export DISNIXOS_USE_NIXOPS=1
        #export DISNIX_TARGET_PROPERTY=target

        #export PASSWORD_STORE_DIR=$PWD/secrets
        export SHELL=${bashInteractive}/bin/bash
      '';
    };
    ## -
    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    #lib = pkgs.lib;
    #builders
    #htmlDocs
    #legacyPackages
    #overlays = pkgs.overlays;
  };
}
