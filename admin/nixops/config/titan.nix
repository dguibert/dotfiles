{ nixpkgs
, nur_dguibert
, home-manager
, hydra
, nix
, ... }@flakes:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    {
      nixpkgs.config = import "${nur_dguibert}/config.nix";
      nixpkgs.overlays = [
        nur_dguibert.overlays.default
        nix.overlay
      ];
    }
    nixpkgs.nixosModules.notDetected
    (import ./titan/configuration.nix)
    #(import "${home-manager}/nixos")
    ## file 'nixpkgs/nixos/modules/misc/assertions.nix' was not found in the Nix search path (add it using $NIX_PATH or -I), at /nix/store/0kj2qmx1g7y1y42icd9aqk9rzc3dvfyd-source/modules/modules.nix:144:17
    #({ pkgs, config, lib, ... }: {
    #  home-manager.users.dguibert = (import ./users/dguibert/home.nix { system="x86_64-linux"; }).withX11 { inherit pkgs lib config; };
    #})
    ({config, lib, pkgs, ...}: {
      environment.shellInit = ''
         export NIX_PATH=nixpkgs=${nixpkgs}:nur_dguibert=${nur_dguibert}
      '';

      nix.autoOptimiseStore = true;
      nix.package = pkgs.nix;
    })
    hydra.nixosModules.hydra
    ({config, lib, pkgs, ...}: {
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
      #    # for building VirtualBox VMs as build artifacts, you might need other
      #    # features depending on what you are doing
          supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
        }
      ];

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


    })
  ];
}

