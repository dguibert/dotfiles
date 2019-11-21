
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

        NIX_OPTIONS=()
        NIX_OPTIONS+=("--option plugin-files ${(pkgs.x86_64-linux.nix-plugins.override { nix = pkgs.x86_64-linux.nix; }).overrideAttrs (o: {
            buildInputs = o.buildInputs ++ [ boehmgc ];
          })}/lib/nix/plugins/libnix-extra-builtins.so")
        NIX_OPTIONS+=("--option extra-builtins-file $(pwd)/extra-builtins.nix")
        export NIX_OPTIONS
      '';
    };
    ## -
    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosConfigurations = with nixpkgs.lib; {
      titan = import ./config/titan.nix flakes;
      rpi31 = import ./config/rpi31.nix flakes;
    };

    nixopsConfigurations.default = with nixpkgs.lib; let
      pass_ = key: if builtins ? extraBuiltins
                   then
                     if builtins.extraBuiltins ? pass then builtins.extraBuiltins.pass key
                     else throw "extraBuiltins.pass undefined"
                   else if builtins ? exec
                     then builtins.exec [ "${toString ./nix-pass.sh}" "${key}" ]
                     else "builtins.exec undefined"
            ;
    in {
      inherit nixpkgs;
      defaults = { config, lib, pkgs, resources, ...}: {
        imports = [
          nixpkgs.nixosModules.notDetected
        ];
        nixpkgs.config = import "${nur_dguibert}/config.nix";
        nixpkgs.overlays = [
          nix.overlay
          nixops.overlay
          nur_dguibert.overlays.default
        ];
        nix.autoOptimiseStore = true;
        nix.package = pkgs.nix;
        #(import "${home-manager}/nixos")
        ## file 'nixpkgs/nixos/modules/misc/assertions.nix' was not found in the Nix search path (add it using $NIX_PATH or -I), at /nix/store/0kj2qmx1g7y1y42icd9aqk9rzc3dvfyd-source/modules/modules.nix:144:17
        #({ pkgs, config, lib, ... }: {
        #  home-manager.users.dguibert = (import ./users/dguibert/home.nix { system="x86_64-linux"; }).withX11 { inherit pkgs lib config; };
        #})
        environment.shellInit = ''
          export NIX_PATH=nixpkgs=${nixpkgs}:nur_dguibert=${nur_dguibert}
          NIX_OPTIONS=()
          NIX_OPTIONS+=("--option plugin-files ${(pkgs.nix-plugins.override { nix = config.nix.package; }).overrideAttrs (o: {
              buildInputs = o.buildInputs ++ [ pkgs.boehmgc ];
            })}/lib/nix/plugins/libnix-extra-builtins.so")
          NIX_OPTIONS+=("--option extra-builtins-file $(pwd)/extra-builtins.nix")
          export NIX_OPTIONS
        '';
        nix.systemFeatures = [ "recursive-nix" ] ++ # default
          [ "nixos-test" "benchmark" "big-parallel" "kvm" ] ++
          lib.optionals (pkgs.stdenv.isx86_64 && pkgs.hostPlatform.platform ? gcc.arch) (
            # a x86_64 builder can run code for `platform.gcc.arch` and minor architectures:
            [ "gccarch-${pkgs.hostPlatform.platform.gcc.arch}" ] ++ {
              sandybridge    = [ "gccarch-westmere" ];
              ivybridge      = [ "gccarch-westmere" "gccarch-sandybridge" ];
              haswell        = [ "gccarch-westmere" "gccarch-sandybridge" "gccarch-ivybridge" ];
              broadwell      = [ "gccarch-westmere" "gccarch-sandybridge" "gccarch-ivybridge" "gccarch-haswell" ];
              skylake        = [ "gccarch-westmere" "gccarch-sandybridge" "gccarch-ivybridge" "gccarch-haswell" "gccarch-broadwell" ];
              skylake-avx512 = [ "gccarch-westmere" "gccarch-sandybridge" "gccarch-ivybridge" "gccarch-haswell" "gccarch-broadwell" "gccarch-skylake" ];
            }.${pkgs.hostPlatform.platform.gcc.arch} or []
        );
      };

      orsine = { config, pkgs, resources, ... }: {
        imports = [
          (import ./config/orsine/configuration.nix)
        ];
      };
      titan = { config, lib, pkgs, resources, ... }: {
        imports = [
          hydra.nixosModules.hydra
          (import ./config/titan/configuration.nix)
        ];

        services.hydra-dev = {
          enable = true;
          hydraURL = "http://localhost:3000";
          notificationSender = "hydra@orsin.freeboxos.fr";
          port = 3000;
          useSubstitutes = true;
          extraConfig = ''
            store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/hydra.orsin.freeboxos.fr-1/secret

            max_concurrent_evals = 1
          '';
          #buildMachinesFiles = [ /*"/etc/nix/machines"*/ ];
        };
        nix.buildMachines = [
          {
            hostName = "localhost";
            systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
            maxJobs = 16;
            # for building VirtualBox VMs as build artifacts, you might need other features depending on what you are doing
            supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark" "recursive-nix" ];
          }
        ];
        deployment.keys.id_buildfarm = {
          text = pass_ "id_buildfarm";
          destDir = "/etc/nix";
          user = "hydra";
          group = "hydra";
          permissions = "0440";
        };

        services.postgresql = {
          package = pkgs.postgresql_9_6;
          dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
        };

        systemd.services.hydra-manual-setup = {
          description = "Create Admin User for Hydra";
          serviceConfig.Type = "oneshot";
          serviceConfig.RemainAfterExit = true;
          wantedBy = [ "multi-user.target" ];
          requires = [ "hydra-init.service" ];
          after = [ "hydra-init.service" ];
          environment = lib.mkForce config.systemd.services.hydra-init.environment;
          script = ''
            if [ ! -e ~hydra/.setup-is-complete ]; then
              # create admin user
              /run/current-system/sw/bin/hydra-create-user dguibert --full-name 'David G. User' --email-address 'dguibert@orsin.freeboxos.fr' --password foobar --role admin
              # create signing keys
              /run/current-system/sw/bin/install -d -m 551 /etc/nix/hydra.orsin.freeboxos.fr-1
              /run/current-system/sw/bin/nix-store --generate-binary-cache-key hydra.orsin.freeboxos.fr-1 /etc/nix/hydra.orsin.freeboxos.fr-1/secret /etc/nix/hydra.orsin.freeboxos.fr-1/public
              /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/hydra.orsin.freeboxos.fr-1
              /run/current-system/sw/bin/chmod 440 /etc/nix/hydra.orsin.freeboxos.fr-1/secret
              /run/current-system/sw/bin/chmod 444 /etc/nix/hydra.orsin.freeboxos.fr-1/public
              # create cache (https://qfpl.io/posts/nix/starting-simple-hydra/)
              /run/current-system/sw/bin/install -d -m 755 /var/lib/hydra/cache
              /run/current-system/sw/bin/chown -R hydra-queue-runner:hydra /var/lib/hydra/cache
              # done
              touch ~hydra/.setup-is-complete
            fi
          '';
        };
      };
      rpi31 = { config, lib, pkgs, resources, ... }: {
        imports = [
          (import "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix")
          (import "${nixpkgs}/nixos/modules/profiles/minimal.nix")
          (import ./config/rpi31/configuration.nix)
        ];
        nixpkgs.localSystem.system = "aarch64-linux";
        programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";
        #assertions = lib.singleton {
        #  assertion = pkgs.stdenv.system == "aarch64-linux";
        #  message = "rpi31-configuration.nix can be only built natively on Aarch64 / ARM64; " +
        #    "it cannot be cross compiled";
        #};
      };
    };
  };
}
