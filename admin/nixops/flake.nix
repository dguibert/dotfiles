{
  description = "Configurations of my systems";

  # To update all inputs:
  # $ nix flake update --recreate-lock-file
  inputs.home-manager.url = "github:dguibert/home-manager/pu";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";

  inputs.hydra.url = "github:dguibert/hydra/pu";
  inputs.hydra.inputs.nix.follows = "nix";
  inputs.hydra.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";

  inputs.nix.follows = "nixpkgs/nix";

  inputs.nur.url = "github:nix-community/NUR";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";

  inputs.nixpkgs.url = "github:dguibert/nur-packages?refs=master";

  inputs.terranix = { url = "github:mrVanDalo/terranix"; flake = false; };
  #inputs."nixos-18.03".url   = "github:nixos/nixpkgs-channels/nixos-18.03";
  #inputs."nixos-18.09".url   = "github:nixos/nixpkgs-channels/nixos-18.09";
  #inputs."nixos-19.03".url   = "github:nixos/nixpkgs-channels/nixos-19.03";
  inputs.base16.url = "github:SenchoPens/base16.nix";
  inputs.base16.inputs.nixpkgs.follows = "nixpkgs";
  inputs.base16-schemes = { url = github:base16-project/base16-schemes; flake = false; };
  inputs.base16-tmux = { url = github:base16-project/base16-tmux; flake = false; };
  inputs.base16-vim = { url = github:base16-project/base16-vim; flake = false; };
  inputs.base16-shell = { url = github:base16-project/base16-shell; flake = false; };
  inputs.gitignore = { url = "github:hercules-ci/gitignore"; flake = false; };

  inputs.nxsession.url = "github:dguibert/nxsession";
  inputs.nxsession.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";
  inputs.nxsession.inputs.flake-utils.follows = "flake-utils";

  # For accessing `deploy-rs`'s utility Nix functions
  inputs.deploy-rs.url = "github:dguibert/deploy-rs/pu";
  inputs.deploy-rs.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";

  #inputs.nixpkgs-wayland.url = "github:colemickens/nixpkgs-wayland";
  # only needed if you use as a package set:
  #inputs.nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nixpkgs-wayland.inputs.master.follows = "master";
  #inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";
  inputs.emacs-overlay.url = "github:dguibert/emacs-overlay";
  inputs.emacs-overlay.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";

  inputs.chemacs.url = "github:plexus/chemacs2";
  inputs.chemacs.flake = false;

  inputs.flake-utils.follows = "nixpkgs/flake-utils";

  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";

  nixConfig.extra-experimental-features = [ "nix-command" "flakes" ];

  outputs = { self, ... }@inputs:
    let
      # Memoize nixpkgs for different platforms for efficiency.
      inherit (self) outputs;
      commonOverlays = [
        inputs.emacs-overlay.overlay
        inputs.nixpkgs.overlays.emacs
        inputs.nxsession.overlay
        #inputs.nixpkgs-wayland.overlay
        inputs.self.overlays.default
      ];
      nixpkgsFor = system:
        import inputs.nixpkgs.inputs.nixpkgs {
          inherit system;
          overlays = inputs.nixpkgs.legacyPackages.${system}.overlays ++ commonOverlays;
          config = { allowUnfree = true; } // inputs.nixpkgs.legacyPackages.${system}.config;
          #config.contentAddressedByDefault = true;
        };

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

    in
    inputs.nixpkgs.lib.recursiveUpdate
      (inputs.flake-utils.lib.eachSystem supportedSystems (system:
        let
          pkgs = nixpkgsFor system;
        in
        rec {

          devShells.default = pkgs.callPackage ./shell.nix {
            inherit inputs;
            inherit (inputs.sops-nix.packages.${system}) sops-import-keys-hook ssh-to-pgp;
            deploy-rs = inputs.deploy-rs.packages.${system}.deploy-rs;
            pre-commit-check-shellHook = inputs.self.checks.${system}.pre-commit-check.shellHook;
          };
          legacyPackages = pkgs;

          apps = import ./apps {
            inherit (outputs) lib;
            inherit inputs outputs;
            nixpkgs_to_use = {
              #default = builtins.trace "using default nixpkgs" inputs.nixpkgs;
              default = builtins.trace "using default nixpkgs" outputs.legacyPackages;
            };
          };

          checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
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

        }))
      (rec {
        lib = inputs.nixpkgs.lib;

        overlays = import ./overlays { inherit lib inputs; };

        ## - hydraJobs: A nested set of derivations built by Hydra.
        ##
        ## -
        ## - NixOS-related outputs such as nixosModules and nixosSystems.
        nixosModules = import ./modules { inherit lib; };

        ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
        homeManagerModules = import ./hm-modules { inherit lib; };

        nixosConfigurations = import ./hosts {
          inherit lib inputs outputs;
          systems = {
            default = "x86_64-linux";
            "rpi30" = "aarch64-linux";
            "rpi41" = "aarch64-linux";
          };
          pkgs_to_use = {
            rpi01 = self.legacyPackages.x86_64-linux.pkgsCross.raspberryPi;
          };
        };

        homeConfigurations = import ./homes {
          inherit lib inputs outputs;
          nixpkgs_to_use = {
            #default = builtins.trace "using default nixpkgs" inputs.nixpkgs;
            default = builtins.trace "using default nixpkgs" self;
          };
          systems = {
            default = "x86_64-linux";
            "root@aarch64-linux" = "aarch64-linux";
            "root@x86_64-linux" = "x86_64-linux";
            "dguibert@rpi31" = "aarch64-linux";
            "dguibert@rpi41" = "aarch64-linux";
          };
        };

        deploy.nodes = builtins.foldl' inputs.nixpkgs.lib.recursiveUpdate { } [
          (inputs.nixpkgs.lib.mapAttrs
            (host: nixosConfig:
              let
                system = nixosConfig.config.nixpkgs.localSystem.system;
              in
              {
                hostname = "${nixosConfig.config.networking.hostName}";
                sshOpts = [ "-o" "ControlMaster=no" ]; # https://github.com/serokell/deploy-rs/issues/106
                profiles.system.path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfig;
                profiles.system.user = "root";
                # Fast connection to the node. If this is true, copy the whole closure instead of letting the node substitute.
                fastConnection = true;

                # If the previous profile should be re-activated if activation fails.
                autoRollback = true;

                # See the earlier section about Magic Rollback for more information.
                # This defaults to `true`
                magicRollback = false;

                # root profiles
                profiles.root.path = inputs.deploy-rs.lib.${system}.activate.custom homeConfigurations."root@${system}".activationPackage "./activate";
                profiles.root.user = "root";
                # dguibert profiles
                #profiles.dguibert.path = inputs.deploy-rs.lib.${system}.activate.custom homeConfigurations."dguibert@${system}".activationPackage "./activate";
                #profiles.dguibert.user = "dguibert";
              })
            (builtins.removeAttrs inputs.self.nixosConfigurations [ "iso" ]))
          # dguibert profiles
          (inputs.nixpkgs.lib.mapAttrs
            (host: homeConfig:
              let
                system = nixosConfigurations.${host}.config.nixpkgs.localSystem.system;
              in
              {
                #profiles.root.path = inputs.deploy-rs.lib.aarch64-linux.activate.custom
                profiles.dguibert.path = inputs.deploy-rs.lib.${system}.activate.custom homeConfig.activationPackage "./activate";
                profiles.dguibert.user = "dguibert";
              })
            {
              rpi31 = homeConfigurations."dguibert@rpi31";
              rpi41 = homeConfigurations."dguibert@rpi41";
              titan = homeConfigurations."dguibert@titan";
              t580 = homeConfigurations."dguibert@t580";
            }
          )
          (
            let
              genProfile = name: profile: {
                path = inputs.deploy-rs.lib.x86_64-linux.activate.custom homeConfigurations."${name}".activationPackage ''
                  export NIX_STATE_DIR=${homeConfigurations."${name}".config.home.sessionVariables.NIX_STATE_DIR}
                  export NIX_PROFILE=${homeConfigurations."${name}".config.home.sessionVariables.NIX_PROFILE}
                  ./activate
                '';
                sshUser = "bguibertd";
                profilePath = "${homeConfigurations."${name}".pkgs.nixStore}/var/nix/profiles/per-user/bguibertd/${profile}";
              };
            in
            {
              genji = {
                hostname = "genji";
                sshOpts = [ "-o" "ControlMaster=no" ]; # https://github.com/serokell/deploy-rs/issues/106
                fastConnection = true;
                autoRollback = false;
                magicRollback = false;

                profiles.bguibertd = genProfile "bguibertd@genji" "hm-x86_64";
              };
              spartan = {
                hostname = "spartan";
                sshOpts = [ "-o" "ControlMaster=no" ]; # https://github.com/serokell/deploy-rs/issues/106
                fastConnection = true;
                autoRollback = false;
                magicRollback = false;

                profiles.bguibertd = genProfile "bguibertd@spartan" "hm";
                profiles.bguibertd-x86_64 = genProfile "bguibertd@spartan-x86_64" "hm-x86_64";
              };
              levante = {
                hostname = "levante";
                sshOpts = [ "-o" "ControlMaster=no" ]; # https://github.com/serokell/deploy-rs/issues/106
                fastConnection = true;
                autoRollback = false;
                magicRollback = false;

                profiles.dguibert = genProfile "dguibert@levante" "hm";

              };
            }
          )

          ({ })
        ];

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy)
          (inputs.nixpkgs.lib.getAttrs supportedSystems inputs.deploy-rs.lib);

      });
}
