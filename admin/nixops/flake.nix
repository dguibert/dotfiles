
{
  epoch = 201909;

  description = "Configurations of my systems";

  # git(+http|+https|+ssh|+git|+file|):(//<server>)?<path>(\?<params>)?
  # git+file:///home/my-user/some-repo/some-repo
  # ref, rev, dir
  inputs = {
    #nix.uri = "/home/dguibert/code/nix";
    #nixpkgs.uri = "github:dguibert/nixpkgs/pu";
    nixops.uri = "/home/dguibert/code/nixops";
    nixpkgs.uri = "/home/dguibert/code/nixpkgs";
    nix.uri = "/home/dguibert/code/nix";
    hydra.uri = "/home/dguibert/code/hydra";
    #nur_dguibert.uri = "github:dguibert/nur-packages/pu";
    nur_dguibert.uri = "/home/dguibert/nur-packages";
    #"nixos-18.03".uri = "github:nixos/nixpkgs-channels/nixos-18.03";
    #"nixos-18.09".uri = "github:nixos/nixpkgs-channels/nixos-18.09";
    #"nixos-19.03".uri = "github:nixos/nixpkgs-channels/nixos-19.03";
    base16-nix = { uri  = "github:atpotts/base16-nix"; flake=false; };
    NUR = { uri  = "github:nix-community/NUR"; flake=false; };
    gitignore = { uri  = "github:hercules-ci/gitignore"; flake=false; };
    home-manager = { uri = "/home/dguibert/code/home-manager"; flake=false; };

    #terranix = { uri = "https://github.com/mrVanDalo/terranix"; flake=false; };
    terranix = { uri = "/home/dguibert/code/terranix"; flake=false; };
  };

  outputs = { self, nixpkgs
            , nur_dguibert
	    , base16-nix
	    , NUR
	    , gitignore
	    , home-manager
	    , terranix
	    , hydra
	    , nix
	    , nixops
            }@flakes: let
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      pkgs = forAllSystems (system: import "${nur_dguibert}/pkgs.nix" {
        inherit nixpkgs;
        localSystem = { inherit system; };# FIXME hard coded for now
        overlays = [ nix.overlay nixops.overlay nur_dguibert.overlay ];
      });
    in rec {

    ## - packages: A set of derivations used as a default by most nix commands. For example, nix run nixpkgs:hello uses the packages.hello attribute of the nixpkgs flake. It cannot contain any non-derivation attributes. This also means it cannot be a nested set! (The rationale is that supporting nested sets requires Nix to evaluate each attribute in the set, just to discover which packages are provided.)
    #packages.hello = nixpkgs.provides.packages.hello;
    packages = forAllSystems (system: {
      inherit (pkgs."${system}") hello nix;
    });

    ## - defaultPackage: A derivation used as a default by most nix commands if no attribute is specified. For example, nix run dwarffs uses the defaultPackage attribute of the dwarffs flake.
    ##
    ## - checks: A non-nested set of derivations built by the nix flake check command, and by Hydra if a flake does not have a hydraJobs attribute.
    checks.hello = packages.hello;
    ##
    ## - hydraJobs: A nested set of derivations built by Hydra.
    ##
    ## - devShell: A derivation that defines the shell environment used by nix dev-shell if no specific attribute is given. If it does not exist, then nix dev-shell will use defaultPackage.
    devShell.x86_64-linux = with pkgs.x86_64-linux; let
      my-terraform = terraform.withPlugins (p: with p; [
        libvirt
        random
        external
        p."null"
      ]);
      terranix_ = callPackages terranix {};
    in mkEnv {
      name = "deploy";
      buildInputs = [ nix jq
        terranix_
        jq

	      #my-terraform
        terraform-landscape
        (writeShellScriptBin "terraform" ''
	        set -x
	        #export TF_VAR_wireguard_deploy_nixos_orsine="`${pass}/bin/pass orsine/wireguard_key`"
          #export TF_VAR_wireguard_deploy_nixos_rpi31="`${pass}/bin/pass rpi31/wireguard_key`"
          #export TF_VAR_wireguard_deploy_nixos_titan="`${pass}/bin/pass titan/wireguard_key`"
          #export TF_VAR_wireguard_deploy_nixos_vbox_57nvj72="`${pass}/bin/pass vbox-57nvj72/wireguard_key`"
          set +x
          ${my-terraform}/bin/terraform "$@"
        '')

        pkgs.x86_64-linux.nixops
      ];
      shellHook = ''
        unset NIX_INDENT_MAKE
        unset IN_NIX_SHELL NIX_REMOTE
        unset TMP TMPDIR

        # https://blog.wearewizards.io/how-to-use-nixops-in-a-team
        export GIT_DIR=$HOME/.mgit/dotfiles/.git
        export NIXOPS_STATE=secrets/deploy.nixops

        export DISNIXOS_USE_NIXOPS=1
        export DISNIX_TARGET_PROPERTY=target

        export PASSWORD_STORE_DIR=$PWD/secrets
        export SHELL=${bashInteractive}/bin/bash
      '';
    };
    ## -
    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosConfigurations = with nixpkgs.lib; {
      orsine = import ./config/orsine.nix flakes;
      titan = import ./config/titan.nix flakes;
      rpi31 = import ./config/rpi31.nix flakes;
    };

    nixopsConfigurations.default = with nixpkgs.lib; {
      inherit nixpkgs;
      orsine = { config, pkgs, resources, ... }: {
      };
      titan = { config, pkgs, resources, ... }: {
      };
      rpi31 = { config, pkgs, resources, ... }: {
      };
    };

    nixosModules.systemTarget = import ./modules/system-target.nix;
    #lib = pkgs.lib;
    #builders
    #htmlDocs
    #legacyPackages
    #overlays = pkgs.overlays;
  };
}
