{
  description = "Configurations of my systems";

  inputs = {
    home-manager. url    = "github:dguibert/home-manager/pu";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hydra.url            = "github:dguibert/hydra/pu";
    hydra.inputs.nix.follows = "nix";
    hydra.inputs.nixpkgs.follows = "nixpkgs";

    nixops.url           = "github:dguibert/nixops/pu";
    nixops.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url          = "github:dguibert/nixpkgs/pu";

    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    nur_dguibert.url     = "github:dguibert/nur-packages/pu";
    nur_dguibert.inputs.nix.follows = "nix";
    #nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
    #nur_dguibert_envs.url= "/home/dguibert/nur-packages?dir=envs";
    terranix             = { url = "github:mrVanDalo/terranix"; flake=false; };
    #"nixos-18.03".url   = "github:nixos/nixpkgs-channels/nixos-18.03";
    #"nixos-18.09".url   = "github:nixos/nixpkgs-channels/nixos-18.09";
    #"nixos-19.03".url   = "github:nixos/nixpkgs-channels/nixos-19.03";
    base16-nix           = { url  = "github:atpotts/base16-nix"; flake=false; };
    NUR                  = { url  = "github:nix-community/NUR"; flake=false; };
    gitignore            = { url  = "github:hercules-ci/gitignore"; flake=false; };
  };

  outputs = { self, nixpkgs
            , nur_dguibert
            #, nur_dguibert_envs
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

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays =  [
            nix.overlay
            (final: prev: {
              nixops = nixops.defaultPackage."${system}";
            })
            nur_dguibert.overlay
            self.overlay
          ] /*++ nur_dguibert_envs.overlays*/;
          config.allowUnfree = true;
        }
      );

      inherit (import ./extra-builtins.nix { pkgs = nixpkgsFor.x86_64-linux; })
        pass_
        isGitDecrypted_
        sshSignHost_
	wgKeys_
        extra_builtins_file;

    in rec {
    overlay = final: prev: with final; {
      # Patch libvirt to use ebtables-legacy
      libvirt = if prev.libvirt.version <= "5.4.0" && prev.ebtables.version > "2.0.10-4"
        then
          prev.libvirt.overrideAttrs (oldAttrs: rec {
            EBTABLES_PATH="${final.ebtables}/bin/ebtables-legacy";
          })
        else prev.libvirt;

      nixops = prev.nixops.overrideAttrs (o: {
        doCheck = false;
        doInstallCheck = false;
      });

      install-script = drv: with final; writeScript "install-${drv.name}"
      ''#!/usr/bin/env bash
        set -x

        nixos-install --system ${drv} $@

        umount -R /mnt
        zfs set mountpoint=legacy bt580/nixos
        zfs set mountpoint=legacy rt580/tmp
      '';

      deploy = remote: mode: drv: let
          activateCommand = {
            system = ''
              profile=/nix/var/nix/profiles/system
              onRemote sudo -E nix-env -p $profile --set ${drv}
              onRemote sudo -E ${drv}/bin/switch-to-configuration switch
            '';
            home-manager = ''
              onRemote ${drv}/activate
            '';
          }.${mode} or (throw "Unknown deploy mode (${mode})");
        in writeScript "deploy-${mode}-${builtins.replaceStrings ["@"] ["-"] remote}" ''
          #!/usr/bin/env bash
          set -xeuf -o pipefail

          ${lib.optionalString (remote != "") "nix copy --to ssh://${remote}?compress=true ${drv}"}

          onRemote() {
            ${lib.optionalString (remote != "") "ssh ${remote}"} $@
          }

          ${activateCommand}

        '';
    };

    ## - packages: A set of derivations used as a default by most nix commands. For example, nix run nixpkgs:hello uses the packages.hello attribute of the nixpkgs flake. It cannot contain any non-derivation attributes. This also means it cannot be a nested set! (The rationale is that supporting nested sets requires Nix to evaluate each attribute in the set, just to discover which packages are provided.)
    #packages.hello = nixpkgs.provides.packages.hello;
    packages = forAllSystems (system: with nixpkgsFor.${system}; {
      inherit (nixpkgsFor."${system}") hello;

      nix = nixpkgsFor.${system}.nix;
      libuv = nixpkgsFor.${system}.libuv;
      cmake = nixpkgsFor.${system}.cmake;

      rpi31_sd = nixosConfigurations.rpi31.config.system.build.sdImage;
      rpi41_sd = nixosConfigurations.rpi41.config.system.build.sdImage;

      rpi41_cross_sd = nixosConfigurations.rpi41_cross.config.system.build.sdImage;

      install-laptop = install-script nixosConfigurations.laptop-s93efa6b.config.system.build.toplevel;

    });

    ## - defaultPackage: A derivation used as a default by most nix commands if no attribute is specified. For example, nix run dwarffs uses the defaultPackage attribute of the dwarffs flake.
    ##
    ## - checks: A non-nested set of derivations built by the nix flake check command, and by Hydra if a flake does not have a hydraJobs attribute.
    checks.x86_64-linux.hello = packages.x86_64-linux.hello;

    hydraJobs = rec {
      all = nixpkgsFor.x86_64-linux.writeText "all" ''
        #{deploy-rpi31-system  }
        #{deploy-rpi41-system  }

        ${deploy-titan-system  }
        ${deploy-t580-system   }
        ${deploy-orsine-system }

        ${deploy-titan-dguibert}
        ${deploy-t580-dguibert }
        ${deploy-orsine-dguibert}

        #{deploy-rpi31-dguibert}
        #{deploy-rpi41-dguibert}

        ${deploy-titan-root }
        ${deploy-t580-root  }
        ${deploy-orsine-root}
      '';
      rpi01_sd = nixosConfigurations.rpi01.config.system.build.sdImage;

      deploy-rpi31-system   = nixpkgsFor.aarch64-linux.deploy "root@rpi31" "system" nixosConfigurations.rpi31.config.system.build.toplevel;
      deploy-rpi41-system   = nixpkgsFor.aarch64-linux.deploy "root@rpi41" "system" nixosConfigurations.rpi41.config.system.build.toplevel;

      deploy-titan-system   = nixpkgsFor.x86_64-linux.deploy "root@titan"     "system"       nixosConfigurations.titan.config.system.build.toplevel;
      deploy-t580-system    = nixpkgsFor.x86_64-linux.deploy "root@laptop-s93efa6b" "system" nixosConfigurations.laptop-s93efa6b.config.system.build.toplevel;
      deploy-orsine-system  = nixpkgsFor.x86_64-linux.deploy "root@orsine"    "system"       nixosConfigurations.orsine.config.system.build.toplevel;

      deploy-titan-dguibert = nixpkgsFor.x86_64-linux.deploy "dguibert@titan"  "home-manager" homeConfigurations.dguibert.x11.x86_64-linux.activationPackage;
      deploy-t580-dguibert  = nixpkgsFor.x86_64-linux.deploy "dguibert@laptop-s93efa6b" "home-manager" homeConfigurations.dguibert.x11.x86_64-linux.activationPackage;
      deploy-orsine-dguibert= nixpkgsFor.x86_64-linux.deploy "dguibert@orsine" "home-manager" homeConfigurations.dguibert.x11.x86_64-linux.activationPackage;

      deploy-rpi31-dguibert = nixpkgsFor.aarch64-linux.deploy "dguibert@rpi31" "home-manager" homeConfigurations.dguibert.no-x11.aarch64-linux.activationPackage;
      deploy-rpi41-dguibert = nixpkgsFor.aarch64-linux.deploy "dguibert@rpi31" "home-manager" homeConfigurations.dguibert.no-x11.aarch64-linux.activationPackage;

      deploy-titan-root  = nixpkgsFor.x86_64-linux.deploy "root@titan" "home-manager" homeConfigurations.root.x86_64-linux.activationPackage;
      deploy-t580-root   = nixpkgsFor.x86_64-linux.deploy "root@laptop-s93efa6b" "home-manager" homeConfigurations.root.x86_64-linux.activationPackage;
      deploy-orsine-root = nixpkgsFor.x86_64-linux.deploy "root@orsine" "home-manager" homeConfigurations.root.x86_64-linux.activationPackage;

      #hm_dguibert_x11 = homeConfigurations.dguibert.x11.x86_64-linux.activationPackage;
      #hm_dguibert_spartan = homeConfigurations.dguibert_spartan.x11.x86_64-linux.activationPackage;
      iso = (nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          nixopsConfigurations.default.defaults
          { key = "nixops-stuff";
            # Make NixOps's deployment.* options available.
            imports = [ "${nixops}/nix/options.nix" "${nixops}/nix/resource.nix" ];
            # Provide a default hostname and deployment target equal
            # to the attribute name of the machine in the model.
            networking.hostName = "iso";
            deployment.targetHost = "iso";
            environment.checkConfigurationOptions = true;
          }
	  ({ pkgs, lib, ...}: {
            users.extraUsers.root.initialPassword = lib.mkForce "OhPha3gu";
            networking.wireguard-mesh.enable = lib.mkForce false;
	  })
        ];
      }).config.system.build.isoImage;
    };
    ##
    ## - hydraJobs: A nested set of derivations built by Hydra.
    ##
    ## - devShell: A derivation that defines the shell environment used by nix dev-shell if no specific attribute is given. If it does not exist, then nix dev-shell will use defaultPackage.
    devShell = forAllSystems (system: with nixpkgsFor.${system}; let
      my-terraform = terraform.withPlugins (p: with p; [
        libvirt
        p."null"
      ]);
      terranix_ = callPackage terranix {};
    in mkEnv rec {
      name = "deploy";
      buildInputs = [
        nixpkgsFor.x86_64-linux.nix
        nixpkgsFor.x86_64-linux.nixops
        #nix-diff # Package ‘nix-diff-1.0.8’ in /nix/store/1bzvzc4q4dr11h1zxrspmkw54s7jpip8-source/pkgs/development/haskell-modules/hackage-packages.nix:174705 is marked as broken, refusing to evaluate.

        terranix_
        jq

        #my-terraform
        terraform-landscape
        (writeShellScriptBin "terraform" ''
          set -x
          #export TF_VAR_wireguard_deploy_nixos_orsine="`${pass}/bin/pass orsine/wireguard_key`"
          #export TF_VAR_wireguard_deploy_nixos_rpi31="`${pass}/bin/pass rpi31/wireguard_key`"
          #export TF_VAR_wireguard_deploy_nixos_titan="`${pass}/bin/pass titan/wireguard_key`"
          set +x
          ${my-terraform}/bin/terraform "$@"
        '')

      ];
      shellHook = ''
        unset NIX_INDENT_MAKE
        unset IN_NIX_SHELL NIX_REMOTE
        unset TMP TMPDIR

        # https://blog.wearewizards.io/how-to-use-nixops-in-a-team
        export NIXOPS_STATE=secrets/deploy.nixops

        export DISNIXOS_USE_NIXOPS=1
        export DISNIX_TARGET_PROPERTY=target

        export PASSWORD_STORE_DIR=$PWD/secrets
        export SHELL=${bashInteractive}/bin/bash

        export XDG_CACHE_HOME=$HOME/.cache/${name}
        unset NIX_STORE NIX_DAEMON
        NIX_PATH=
        ${lib.concatMapStrings (f: ''
          NIX_PATH+=:${toString f}=${toString flakes.${f}}
        '') (builtins.attrNames flakes) }
        export NIX_PATH

        NIX_OPTIONS=()
        NIX_OPTIONS+=("--option plugin-files ${(nixpkgsFor.x86_64-linux.nix-plugins.override { nix = nixpkgsFor.x86_64-linux.nix; }).overrideAttrs (o: {
            buildInputs = o.buildInputs ++ [ boehmgc ];
          })}/lib/nix/plugins/libnix-extra-builtins.so")
        NIX_OPTIONS+=("--option extra-builtins-file ${extra_builtins_file nixpkgsFor.${system}}")
        export NIX_OPTIONS
      '';
    });
    ## -
    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosModules.mopidy-server = import ./roles/mopidy.nix;
    nixosConfigurations = let
      nodes = (import ./eval-machine-info.nix {
        system = "x86_64-linux";
        networks = [ (nixopsConfigurations.default // { _file="flake.nix"; }) ];
        checkConfigurationOptions = true;
        uuid = "fca2af7a-1911-11e7-b752-02422684ac68";
        deploymentName = "deploy";
        args = {};
        pluginNixExprs = [];
        inherit nixpkgs nixops;
      }).nodes;
    in nodes // {
      rpi01 = nixpkgs.lib.nixosSystem {
        modules = [
          ({ config, lib, pkgs, resources, ... }: {
            #deployment.targetPort = 443;
            #deployment.targetHost = "192.168.1.13";
            #deployment.targetPort = 22322;
            imports = [
              #(import "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image-raspberrypi.nix")
              (import "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image.nix")
              #(import "${nixpkgs}/nixos/modules/profiles/minimal.nix")
              #(import "${nixpkgs}/nixos/modules/profiles/base.nix")
              (import ./hosts/rpi01/configuration.nix)
            ];
            boot.loader.grub.enable = false;
            boot.loader.raspberryPi.enable = true;
            boot.loader.raspberryPi.version = 0;
            boot.loader.raspberryPi.uboot.enable = true;
            boot.loader.raspberryPi.uboot.configurationLimit = 10;
            boot.loader.raspberryPi.firmwareConfig = ''
              disable_splash=1
            '';
            #  dtparam=audio=on
            #  gpu_mem=${toString gpu-mem}
            #  dtoverlay=${gpu-overlay}
            #'';


            boot.consoleLogLevel = lib.mkDefault 7;
            boot.kernelPackages = pkgs.linuxPackages_rpi1;

            sdImage = {
              firmwareSize = 512;
              populateFirmwareCommands = let
                configTxt = pkgs.writeText "config.txt" ''
                  # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
                  # when attempting to show low-voltage or overtemperature warnings.
                  avoid_warnings=1

                  [pi0]
                  kernel=u-boot-rpi0.bin

                  [pi1]
                  kernel=u-boot-rpi1.bin
                '';
                in ''
                  (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
                  cp ${pkgs.ubootRaspberryPiZero}/u-boot.bin firmware/u-boot-rpi0.bin
                  cp ${pkgs.ubootRaspberryPi}/u-boot.bin firmware/u-boot-rpi1.bin
                  cp ${configTxt} firmware/config.txt
                '';
              populateRootCommands = ''
              '';
            };

            fileSystems = {
              "/boot" = {
                device = "/dev/disk/by-label/FIRMWARE";
                fsType = "vfat";
              };
            };

            #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
            nixpkgs.localSystem.system = "x86_64-linux";
            nixpkgs.crossSystem = { config = "armv6l-unknown-linux-gnueabihf"; };
            #nixpkgs.localSystem.system = "armv6l-linux";
            nixpkgs.overlays = [
              nix.overlay
              nixops.overlay
              nur_dguibert.overlays.default
              (final: prev: {
                # don't build qt5
                # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
                pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
                git = prev.git.override { perlSupport = false; };
              })
            ];

            services.nixosManual.showManual = lib.mkForce false;
            fileSystems."/".options = [ "defaults" "discard" ];

            #programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";
          })
        ];
      };
    };

    nixopsConfigurations.default = with nixpkgs.lib; rec {
      inherit nixpkgs;
      defaults = { config, lib, pkgs, resources, ...}: let
        ssh_keys = {
          ssh_host_ed25519_key = sshSignHost_ "ssh-ca/home"
                                  config.networking.hostName
                                  "${config.networking.hostName}"
                                  "ed25519";
          ssh_host_rsa_key = sshSignHost_ "ssh-ca/home"
                                  config.networking.hostName
                                  "${config.networking.hostName}"
                                  "rsa";
        };
        upload_key = name: attr: {
          text = ssh_keys.${name}.${attr};
          destDir = "/persist/etc/ssh";
        };

      in {
        imports = [
          nixpkgs.nixosModules.notDetected
          modules/wireguard-mesh.nix
        ];

        nixpkgs.config = import "${nur_dguibert}/config.nix";
        nixpkgs.overlays = [
          nix.overlay
          nixops.overlay
          nur_dguibert.overlays.default
          self.overlay
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
          NIX_OPTIONS+=("--option extra-builtins-file ${extra_builtins_file pkgs}")
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

        programs.gnupg.agent.pinentryFlavor = "gtk2";

        networking.wireguard-mesh.enable = true;
        networking.wireguard-mesh.peers = {
          rpi31 = {
            ipv4Address = "10.147.27.13/32";
            listenPort = 500;
            publicKey  = (wgKeys_ "rpi31/wireguard_key").publicKey;
            endpoint   = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
            persistentKeepalive = 25;
          };
          orsine = {
            ipv4Address = "10.147.27.128/32";
            listenPort = 501;
            publicKey  = (wgKeys_ "orsine/wireguard_key").publicKey;
            endpoint   = "192.168.1.32:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
          };
          titan = {
            ipv4Address = "10.147.27.24/32";
            listenPort = 503;
            publicKey  = (wgKeys_ "titan/wireguard_key").publicKey;
            endpoint   = "192.168.1.24:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
          };
          laptop-s93efa6b = {
            ipv4Address = "10.147.27.17/32";
            listenPort = 504;
            publicKey  = (wgKeys_ "laptop-s93efa6b/wireguard_key").publicKey;
            endpoint   = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
          };
          rpi41 = {
            ipv4Address = "10.147.27.14/32";
            listenPort = 505;
            publicKey  = (wgKeys_ "rpi41/wireguard_key").publicKey;
            endpoint   = "orsin.freeboxos.fr:${toString config.networking.wireguard-mesh.peers."${config.networking.hostName}".listenPort}";
            persistentKeepalive = 25;
          };
          rpi01 = {
            ipv4Address = "10.147.27.10/32";
            listenPort = 506;
            publicKey  = (wgKeys_ "rpi01/wireguard_key").publicKey;
          };
        };
        deployment.keys."wireguard_key" = {
          text = (wgKeys_ "${config.networking.hostName}/wireguard_key").privateKey;
          destDir = "/secrets";
        };

	networking.firewall.allowedUDPPorts = [ 500 501 502 503 504 505 506
          6696 /* babeld */
        ];

        services.openssh.extraConfig = lib.mkOrder 100 ''
          TrustedUserCAKeys /persist/etc/ssh/ssh-ca-home.pub
          HostCertificate /persist/etc/ssh/ssh_host_ed25519_key-cert.pub
          HostCertificate /persist/etc/ssh/ssh_host_rsa_key-cert.pub
        '';
        services.openssh.hostKeys = [
          {
            path = "/persist/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
          {
            path = "/persist/etc/ssh/ssh_host_rsa_key";
            type = "rsa";
            bits = 4096;
          }
        ];
        deployment.keys."ssh_host_rsa_key"     = upload_key "ssh_host_rsa_key" "host_key";
        deployment.keys."ssh_host_rsa_key.pub" = upload_key "ssh_host_rsa_key" "host_key_pub";
        deployment.keys."ssh_host_rsa_key-cert.pub" = upload_key "ssh_host_rsa_key" "host_key_cert_pub";
        deployment.keys."ssh_host_ed25519_key"     = upload_key "ssh_host_ed25519_key" "host_key";
        deployment.keys."ssh_host_ed25519_key.pub" = upload_key "ssh_host_ed25519_key" "host_key_pub";
        deployment.keys."ssh_host_ed25519_key-cert.pub" = upload_key "ssh_host_ed25519_key" "host_key_cert_pub";

        # System wide: echo "@cert-authority * $(cat /etc/ssh/ca.pub)" >>/etc/ssh/ssh_known_hosts
        programs.ssh.knownHosts.ca-home = {
          certAuthority=true;
          publicKey = pass_ "ssh-ca/home.pub";
        };

        deployment.keys."id_buildfarm" = {
          text = pass_ "id_buildfarm";
          destDir = "/etc/nix";
          #user = "root";
          #group = "root";
        };
      };

      orsine = { config, pkgs, resources, ... }: {
        nixpkgs.localSystem.system = "x86_64-linux";
        imports = [
          (import ./hosts/orsine/configuration.nix)
        ];
      };
      titan = { config, lib, pkgs, resources, ... }: {
        nixpkgs.localSystem.system = "x86_64-linux";
        imports = [
          hydra.nixosModules.hydra
          (import ./hosts/titan/configuration.nix)
          self.nixosModules.mopidy-server
        ];
        systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nix/nix-daemon.secrets.env";

        roles.mopidy-server.enable = true;
        roles.mopidy-server.listenAddress = "192.168.1.24";
        roles.mopidy-server.configuration.local.media_dir = "/home/dguibert/Music";
        roles.mopidy-server.configuration.iris.country = "FR";
        roles.mopidy-server.configuration.iris.locale = "FR";

        services.hydra-dev = {
          enable = true;
          hydraURL = "http://localhost:3000";
          notificationSender = "hydra@orsin.freeboxos.fr";
          listenHost = "localhost";
          port = 3000;
          useSubstitutes = true;
          extraConfig = ''
            store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/hydra.orsin.freeboxos.fr-1/secret

            max_concurrent_evals = 1
          '';
          buildMachinesFiles = (lib.optional (config.nix.buildMachines !=[]) "/etc/nix/machines")
            ++ [ "/etc/nix/machines-hydra" ];
        };
	# clean cache directory (nar cache)
	systemd.tmpfiles.rules = [ "d /var/lib/hydra/cache     0775 hydra hydra 1d -" ];

        environment.etc."nix/machines-hydra".text = ''
          localhost x86_64-linux,i686-linux,aarch64-linux - 16 1 kvm,nixos-test,big-parallel,benchmark,recursive-nix
        '';
        nix.extraOptions = ''
          secret-key-files = /etc/nix/cache-priv-key.pem
        '';
        deployment.keys."cache-priv-key.pem" = {
          text = pass_ "titan/cache-priv-key.pem";
          destDir = "/etc/nix";
        };
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
        services.openssh.extraConfig = ''
          Match Group sftponly
          ChrootDirectory %h
          ForceCommand internal-sftp
          AllowTcpForwarding no
          X11Forwarding no
          PasswordAuthentication no
        '';
      };
      rpi31 = { config, lib, pkgs, resources, ... }: {
        #deployment.targetPort = 443;
        deployment.targetHost = "192.168.1.13";
        deployment.targetPort = 22322;
        imports = [
          (import "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix")
          (import "${nixpkgs}/nixos/modules/profiles/minimal.nix")
          (import ./hosts/rpi31/configuration.nix)
        ];
        #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
        #nixpkgs.localSystem.system = "x86_64-linux";
        nixpkgs.localSystem.system = "aarch64-linux";
        nixpkgs.overlays = [
          nix.overlay
          nixops.overlay
          nur_dguibert.overlays.default
          (final: prev: {
            # don't build qt5
            # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
            pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
          })
        ];

        services.nixosManual.showManual = lib.mkForce false;
        fileSystems."/".options = [ "defaults" "discard" ];

        programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";
        #assertions = lib.singleton {
        #  assertion = pkgs.stdenv.system == "aarch64-linux";
        #  message = "rpi31-configuration.nix can be only built natively on Aarch64 / ARM64; " +
        #    "it cannot be cross compiled";
        #};
        services.openssh.extraConfig = ''
          Match Group sftponly
          ChrootDirectory %h
          ForceCommand internal-sftp
          AllowTcpForwarding no
          X11Forwarding no
          PasswordAuthentication no
        '';
        #  echo -n "ss://"`echo -n chacha20-ietf-poly1305:$(pass rpi31/shadowsocks)@$(curl -4 ifconfig.io):443 | base64` | qrencode -t UTF8
        deployment.keys."shadowsocks" = {
          text = pass_ "rpi31/shadowsocks";
          destDir = "/secrets";
          #user = "root";
          #group = "root";
        };
      };
      rpi41_cross = { config, lib, pkgs, resources, ...}: {
        imports = [ rpi41 ];
        nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
        nixpkgs.localSystem.system = builtins.currentSystem or "x86_64-linux";
        networking.hostName = "rpi41";
        # error: Package ‘raspberrypi-firmware-1.20190925’ in /nix/store/v6yxfmgriax99l3hq0lmmqfg0fvj5874-source/pkgs/os-specific/linux/firmware/raspberrypi/default.nix:20 is not supported on ‘x86_64-linux’, refusing to evaluate.
        nixpkgs.config.allowUnsupportedSystem = true;
      };
      rpi41 = { config, lib, pkgs, resources, ... }: {
        #deployment.targetHost = "192.168.1.14";
        deployment.targetPort = 22322;
        imports = [
          (import "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image.nix")
          (import "${nixpkgs}/nixos/modules/profiles/minimal.nix")
          (import "${nixpkgs}/nixos/modules/profiles/base.nix")
          (import ./hosts/rpi41/configuration.nix)
        ];
        boot.loader.grub.enable = false;
        boot.loader.raspberryPi.enable = true;
        boot.loader.raspberryPi.version = 4;
        # error: U-Boot is not yet supported on the raspberry pi 4.
        #boot.loader.raspberryPi.uboot.enable = true;
        #boot.loader.raspberryPi.uboot.configurationLimit = 10;
        boot.kernelPackages = pkgs.linuxPackages_rpi4;

        boot.consoleLogLevel = lib.mkDefault 7;

        sdImage = {
          firmwareSize = 512;
          # This is a hack to avoid replicating config.txt from boot.loader.raspberryPi
          populateFirmwareCommands =
            "${config.system.build.installBootLoader} ${config.system.build.toplevel} -d ./firmware";
          # As the boot process is done entirely in the firmware partition.
          populateRootCommands = "";
        };
        fileSystems = {
          "/boot" = {
            device = "/dev/disk/by-label/FIRMWARE";
            fsType = "vfat";
          };
        };


        #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
        #nixpkgs.localSystem.system = "x86_64-linux";
        nixpkgs.localSystem.system = "aarch64-linux";
        nixpkgs.overlays = [
          nix.overlay
          nixops.overlay
          nur_dguibert.overlays.default
          (final: prev: {
            # don't build qt5
            # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
            pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
          })
        ];

        sdImage.compressImage = false;
        services.nixosManual.showManual = lib.mkForce false;
        fileSystems."/".options = [ "defaults" "discard" ];

        hardware.opengl = {
          enable = true;
          setLdLibraryPath = true;
          package = pkgs.mesa_drivers;
        };
        hardware.deviceTree = {
          base = pkgs.device-tree_rpi;
          overlays = [ "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d.dtbo" ];
        };
        #services.xserver = {
        #  enable = true;
        #  displayManager.slim.enable = true;
        #  desktopManager.gnome3.enable = true;
        #  videoDrivers = [ "modesetting" ];
        #};

        boot.loader.raspberryPi.firmwareConfig = ''
          gpu_mem=192
        '';
        programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";
        #assertions = lib.singleton {
        #  assertion = pkgs.stdenv.system == "aarch64-linux";
        #  message = "rpi31-configuration.nix can be only built natively on Aarch64 / ARM64; " +
        #    "it cannot be cross compiled";
        #};
      };
      laptop-s93efa6b = { config, lib, pkgs, resources, ... }: {
        nixpkgs.localSystem.system = "x86_64-linux";
        imports = [
          (import ./hosts/laptop-s93efa6b/configuration.nix)
        ];
      };
    };
    homeConfigurations.root = forAllSystems (system: home-manager.lib.mkHome system (args: {
      imports = [ (import "${base16-nix}/base16.nix")
                  (import ./users/root/home.nix { system = system; }).home ];
      nixpkgs.pkgs = nixpkgsFor.${system};
    }));
    homeConfigurations.dguibert.no-x11 = forAllSystems (system: home-manager.lib.mkHome system (args: {
      imports = [ (import "${base16-nix}/base16.nix")
                  (import ./users/dguibert/home.nix { system = system; pkgs = nixpkgsFor.${system}; }).withoutX11 ];
      nixpkgs.pkgs = nixpkgsFor.${system};
    }));
    homeConfigurations.dguibert.x11 = forAllSystems (system: home-manager.lib.mkHome system (args: {
      imports = [ (import "${base16-nix}/base16.nix")
                  (import ./users/dguibert/home.nix { system = system; pkgs = nixpkgsFor.${system}; }).withX11 ];
      nixpkgs.pkgs = nixpkgsFor.${system};
    }));
    homeConfigurations.dguibert_spartan.x11 = forAllSystems (system: home-manager.lib.mkHome system (args: {
      imports = [ (import "${base16-nix}/base16.nix")
                  (import ./users/dguibert/home.nix { system = system; pkgs = nixpkgsFor.${system}; }).spartan ];
      nixpkgs.pkgs = nixpkgsFor.${system}.spartan.pkgs;
    }));
  };
}
