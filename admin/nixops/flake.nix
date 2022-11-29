{
  description = "Configurations of my systems";


  # To update all inputs:
  # $ nix flake update --recreate-lock-file
  inputs.home-manager.url = "github:dguibert/home-manager/pu";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.hydra.url = "github:dguibert/hydra/pu";
  inputs.hydra.inputs.nix.follows = "nix";
  inputs.hydra.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:dguibert/nixpkgs/pu";

  inputs.nix.url = "github:dguibert/nix/pu";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nur.url = "github:nix-community/NUR";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nur_dguibert.url = "github:dguibert/nur-packages/pu";
  inputs.nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur_dguibert.inputs.nix.follows = "nix";
  inputs.nur_dguibert.inputs.flake-utils.follows = "flake-utils";

  #inputs.nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
  #inputs.nur_dguibert_envs.url= "git+file:///home/dguibert/nur-packages?dir=envs";
  #inputs.nur_dguibert_envs.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nur_dguibert_envs.inputs.nix.follows     = "nix";
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
  inputs.nxsession.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nxsession.inputs.flake-utils.follows = "flake-utils";

  inputs.dwm-src.url = "github:dguibert/dwm/pu";
  inputs.dwm-src.flake = false;
  inputs.st-src.url = "github:dguibert/st/pu";
  inputs.st-src.flake = false;
  inputs.dwl-src.url = "github:dguibert/dwl/pu";
  inputs.dwl-src.flake = false;
  inputs.somebar-src.url = "git+https://git.sr.ht/~raphi/somebar";
  inputs.somebar-src.flake = false;
  inputs.yambar-src.url = "git+https://codeberg.org/dnkl/yambar.git";
  inputs.yambar-src.flake = false;

  # For accessing `deploy-rs`'s utility Nix functions
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

  #inputs.nixpkgs-wayland.url = "github:colemickens/nixpkgs-wayland";
  # only needed if you use as a package set:
  #inputs.nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nixpkgs-wayland.inputs.master.follows = "master";
  #inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";
  inputs.emacs-overlay.url = "github:dguibert/emacs-overlay";
  inputs.emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";

  inputs.chemacs.url = "github:plexus/chemacs2";
  inputs.chemacs.flake = false;

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, ... }@inputs:
    let
      # Memoize nixpkgs for different platforms for efficiency.
      inherit (self) outputs;
      nixpkgsFor = system:
        import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.nix.overlays.default
            inputs.emacs-overlay.overlay
            inputs.nur.overlay
            inputs.nur_dguibert.overlay
            inputs.nur_dguibert.overlays.extra-builtins
            #nur_dguibert_envs.overlay
            inputs.nxsession.overlay
            #inputs.nixpkgs-wayland.overlay
            inputs.self.overlays.default
          ];
          config.allowUnfree = true;
          #config.contentAddressedByDefault = true;
        };

      inherit (nixpkgsFor "x86_64-linux")
        sopsDecrypt_
        wgPubKey_
        extra_builtins_file;

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

    in
    inputs.nixpkgs.lib.recursiveUpdate
      (inputs.flake-utils.lib.eachSystem supportedSystems (system:
        let pkgs = nixpkgsFor system; in rec {

          devShells.default = pkgs.callPackage ./shell.nix {
            inherit inputs;
            inherit (inputs.sops-nix.packages.${system}) sops-import-keys-hook ssh-to-pgp;
            deploy-rs = inputs.deploy-rs.packages.${system}.deploy-rs;
            pre-commit-check-shellHook = inputs.self.checks.${system}.pre-commit-check.shellHook;
          };
          legacyPackages = pkgs;

          homeConfigurations = inputs.nixpkgs.lib.genAttrs
            (builtins.attrNames (builtins.removeAttrs inputs.self.nixosConfigurations [ "iso" ]))
            (host: inputs.self.nixosConfigurations.${host}.config.home-manager.users) // { };

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
        ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
        nixosModules = import ./modules { inherit lib; };

        #nixosConfigurations.rpi01 = inputs.nixpkgs.lib.nixosSystem {
        #  modules = [
        #    ({ config, lib, pkgs, resources, ... }: {
        #      imports = [
        #        #(import "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix")
        #        (import "${nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix")
        #        #(import "${nixpkgs}/nixos/modules/profiles/minimal.nix")
        #        #(import "${nixpkgs}/nixos/modules/profiles/base.nix")
        #        (import ./hosts/rpi01/configuration.nix)
        #      ];
        #     #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
        #      nixpkgs.localSystem.system = "x86_64-linux";
        #      nixpkgs.crossSystem = { config = "armv6l-unknown-linux-gnueabihf"; };
        #      #nixpkgs.localSystem.system = "armv6l-linux";
        #      nixpkgs.overlays = [
        #        nix.overlay
        #        nur_dguibert.overlays.default
        #        (final: prev: {
        #          # don't build qt5
        #          # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
        #          pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
        #          git = prev.git.override { perlSupport = false; };
        #        })
        #      ];

        #      documentation.nixos.enable = false;
        #      fileSystems."/".options = [ "defaults" "discard" ];

        #      #programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";
        #    })
        #  ];
        #};

        #nixosConfigurations.orsine = inputs.nixpkgs.lib.nixosSystem {
        #  modules = [
        #    ({ config, lib, pkgs, resources, ... }: {
        #      nixpkgs.localSystem.system = "x86_64-linux";
        #      imports = [
        #        outputs.nixosModules.defaults
        #        (import ./hosts/orsine/configuration.nix)
        #      ];
        #    })
        #  ];
        #};


        ## nix build .#nixosConfigurations.iso.config.system.build.isoImage
        nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
          modules = [
            (import "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
            self.nixosModules.zfs
            ({ config, ... }: { zfs-conf.enable = true; })
            ./hosts/iso.nix
            ({ config, lib, pkgs, resources, ... }: {
              nixpkgs.localSystem.system = "x86_64-linux";
            })
            ({ lib, ... }: {
              networking.wireless.interfaces = [ "wlan0" ];
            })
            ({ pkgs, ... }: {
              environment.systemPackages = [
                (pkgs.writeScriptBin "nixos-install-t580" ''
                  #!${pkgs.stdenv.shell}
                  set -eux -o pipefail
                  nixos-install --system ${self.nixosConfigurations.t580.config.system.build.toplevel}
                '')
              ];
            })
          ];
        };

        nixosConfigurations.titan = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            sopsDecrypt_ = (nixpkgsFor "x86_64-linux").sopsDecrypt_;
          };
          modules = [
            ({ config, lib, pkgs, resources, ... }: {
              nixpkgs.localSystem = {
                #gcc.arch = "broadwell"; #E5-2690v4
                #gcc.tune = "broadwell";
                system = "x86_64-linux";
              };
              imports = [
                inputs.hydra.nixosModules.hydra
                (import ./hosts/titan/configuration.nix)
                outputs.nixosModules.defaults
                outputs.nixosModules.yubikey-gpg-conf
                ({ config, ... }: { yubikey-gpg-conf.enable = true; })
                outputs.nixosModules.x11-conf
                ({ config, ... }: { x11-conf.enable = false; })

                outputs.nixosModules.wayland-conf
                ({ config, ... }: { wayland-conf.enable = true; })
              ];
              #hardware.opengl.extraPackages = [ pkgs.vaapiVdpau /*pkgs.libvdpau-va-gl*/ ];

              environment.systemPackages = [ pkgs.pavucontrol pkgs.ipmitool pkgs.ntfs3g ];

              # https://nixos.org/nixops/manual/#idm140737318329504
              role.libvirtd.enable = true;
              #virtualisation.libvirtd.enable = true;
              #virtualisation.anbox.enable = true;
              #services.nfs.server.enable = true;
              virtualisation.docker.enable = true;
              virtualisation.docker.storageDriver = "zfs";
              virtualisation.virtualbox.host.enable = true;

              programs.singularity.enable = true;

              networking.firewall.checkReversePath = false;

              programs.adb.enable = true;

              services.jellyfin.enable = true;
              systemd.services.jellyfin = lib.mkIf config.services.jellyfin.enable {
                serviceConfig.PrivateUsers = lib.mkForce false;
                serviceConfig.PermissionsStartOnly = true;
                preStart = ''
                  set -x
                  #${pkgs.acl}/bin/setfacl -Rm u:jellyfin:rwX,m:rw-,g:jellyfin:rwX,d:u:jellyfin:rwX,d:g:jellyfin:rwX,o:---,d:o:---,d:m:rwx,m;rwx /home/dguibert/Videos/Series/ /home/dguibert/Videos/Movies/
                  ${pkgs.acl}/bin/setfacl -m user:jellyfin:r-x /home/dguibert
                  ${pkgs.acl}/bin/setfacl -m user:jellyfin:r-x /home/dguibert/Videos
                  ${pkgs.acl}/bin/setfacl -m user:jellyfin:rwx /home/dguibert/Videos/Series
                  ${pkgs.acl}/bin/setfacl -m user:jellyfin:rwx /home/dguibert/Videos/Movies
                  ${pkgs.acl}/bin/setfacl -m group:jellyfin:r-x /home/dguibert
                  ${pkgs.acl}/bin/setfacl -m group:jellyfin:r-x /home/dguibert/Videos
                  ${pkgs.acl}/bin/setfacl -m group:jellyfin:rwx /home/dguibert/Videos/Series
                  ${pkgs.acl}/bin/setfacl -m group:jellyfin:rwx /home/dguibert/Videos/Movies
                  set +x
                '';
                unitConfig.RequiresMountsFor = "/home/dguibert/Videos";
              };
              networking.firewall.interfaces."bond0".allowedTCPPorts = [
                8096 /*http*/
                8920 /*https*/
                config.services.step-ca.port
              ];
              systemd.tmpfiles.rules = [
                "L /var/lib/jellyfin/config - - - - /persist/var/lib/jellyfin/config"
                "L /var/lib/jellyfin/data   - - - - /persist/var/lib/jellyfin/data"
              ];

              systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nix/nix-daemon.secrets.env";

              role.mopidy-server.enable = false; # TODO migrate to pipewire
              role.mopidy-server.listenAddress = "192.168.1.24";
              role.mopidy-server.configuration.local.media_dir = "/home/dguibert/Music/mopidy";
              role.mopidy-server.configuration.m3u = {
                enabled = true;
                playlists_dir = "/home/dguibert/Music/playlists";
                base_dir = config.role.mopidy-server.configuration.local.media_dir;
                default_extension = ".m3u8";
              };
              role.mopidy-server.configuration.local.scan_follow_symlinks = true;
              role.mopidy-server.configuration.iris.country = "FR";
              role.mopidy-server.configuration.iris.locale = "FR";

              role.tiny-ca.enable = true;
              services.step-ca.intermediatePasswordFile = config.sops.secrets.orsin-ca-intermediatePassword.path;
              sops.secrets.orsin-ca-intermediatePassword = {
                sopsFile = ./secrets/defaults.yaml;
              };
              role.robotnix-ota-server.enable = true;
              role.robotnix-ota-server.openFirewall = true;

              hardware.pulseaudio = {
                support32Bit = true;
                tcp.enable = true;
                tcp.anonymousClients.allowAll = true;
                tcp.anonymousClients.allowedIpRanges = [ "127.0.0.1" "192.168.1.0/24" ];
              };

              #services.hydra-dev = {
              #  enable = true;
              #  hydraURL = "http://localhost:3000";
              #  notificationSender = "hydra@orsin.freeboxos.fr";
              #  listenHost = "localhost";
              #  port = 3000;
              #  useSubstitutes = true;
              #  extraConfig = ''
              #    store_uri = file:///var/lib/hydra/cache?secret-key=/etc/nix/hydra.orsin.freeboxos.fr-1/secret

              #    max_concurrent_evals = 1
              #  '';
              #  buildMachinesFiles = (lib.optional (config.nix.buildMachines !=[]) "/etc/nix/machines")
              #    ++ [ "/etc/nix/machines-hydra" ];
              #};
              ## clean cache directory (nar cache)
              #systemd.tmpfiles.rules = [ "d /var/lib/hydra/cache     0775 hydra hydra 1d -" ];

              environment.etc."nix/machines-hydra".text = ''
                localhost x86_64-linux,i686-linux - 16 1 kvm,nixos-test,big-parallel,benchmark,recursive-nix
              '';
              nix.extraOptions = ''
                secret-key-files = /etc/nix/cache-priv-key.pem
              '';
              sops.defaultSopsFile = ./hosts/titan/secrets/secrets.yaml;
              sops.secrets."cache-priv-key.pem" = {
                path = "/etc/nix/cache-priv-key.pem";
              };
              #services.postgresql = {
              #  package = pkgs.postgresql_9_6;
              #  dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
              #};

              #systemd.services.hydra-manual-setup = {
              #  description = "Create Admin User for Hydra";
              #  serviceConfig.Type = "oneshot";
              #  serviceConfig.RemainAfterExit = true;
              #  wantedBy = [ "multi-user.target" ];
              #  requires = [ "hydra-init.service" ];
              #  after = [ "hydra-init.service" ];
              #  environment = lib.mkForce config.systemd.services.hydra-init.environment;
              #  script = ''
              #    if [ ! -e ~hydra/.setup-is-complete ]; then
              #      # create admin user
              #      /run/current-system/sw/bin/hydra-create-user dguibert --full-name 'David G. User' --email-address 'dguibert@orsin.freeboxos.fr' --password foobar --role admin
              #      # create signing keys
              #      /run/current-system/sw/bin/install -d -m 551 /etc/nix/hydra.orsin.freeboxos.fr-1
              #      /run/current-system/sw/bin/nix-store --generate-binary-cache-key hydra.orsin.freeboxos.fr-1 /etc/nix/hydra.orsin.freeboxos.fr-1/secret /etc/nix/hydra.orsin.freeboxos.fr-1/public
              #      /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/hydra.orsin.freeboxos.fr-1
              #      /run/current-system/sw/bin/chmod 440 /etc/nix/hydra.orsin.freeboxos.fr-1/secret
              #      /run/current-system/sw/bin/chmod 444 /etc/nix/hydra.orsin.freeboxos.fr-1/public
              #      # create cache (https://qfpl.io/posts/nix/starting-simple-hydra/)
              #      /run/current-system/sw/bin/install -d -m 755 /var/lib/hydra/cache
              #      /run/current-system/sw/bin/chown -R hydra-queue-runner:hydra /var/lib/hydra/cache
              #      # done
              #      touch ~hydra/.setup-is-complete
              #    fi
              #  '';
              #};
              services.openssh.extraConfig = ''
                Match Group sftponly
                ChrootDirectory %h
                ForceCommand internal-sftp
                AllowTcpForwarding no
                X11Forwarding no
                PasswordAuthentication no
              '';
            })
          ];
        };

        nixosConfigurations.rpi31 = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            sopsDecrypt_ = (nixpkgsFor "x86_64-linux").sopsDecrypt_;
          };
          modules = [
            ({ config, lib, pkgs, resources, ... }: {
              #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
              #nixpkgs.localSystem.system = "x86_64-linux";
              nixpkgs.localSystem.system = "aarch64-linux";
              imports = [
                (import "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
                (import ./hosts/rpi31/configuration.nix)
                outputs.nixosModules.defaults
              ];
              nixpkgs.overlays = [
                inputs.nix.overlays.default
                inputs.nur_dguibert.overlays.default
                (final: prev: {
                  # don't build qt5
                  # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
                  pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
                })
              ];

              documentation.nixos.enable = false;
              #fileSystems."/".options = [ "defaults" "discard" ];
              services.fstrim.enable = true;

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
              #  echo -n "ss://"`echo -n chacha20-ietf-poly1305:$(sops --extract '["shadowsocks"]' -d hosts/rpi31/secrets/secrets.yaml)@$(curl -4 ifconfig.io):443 | base64` | qrencode -t UTF8
              sops.secrets.shadowsocks = { };
              sops.defaultSopsFile = ./hosts/rpi31/secrets/secrets.yaml;
            })
          ];
        };
        #rpi41_cross = { config, lib, pkgs, resources, ...}: {
        #  imports = [ rpi41 ];
        #  nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
        #  nixpkgs.localSystem.system = builtins.currentSystem or "x86_64-linux";
        #  networking.hostName = "rpi41";
        #  # error: Package ‘raspberrypi-firmware-1.20190925’ in /nix/store/v6yxfmgriax99l3hq0lmmqfg0fvj5874-source/pkgs/os-specific/linux/firmware/raspberrypi/default.nix:20 is not supported on ‘x86_64-linux’, refusing to evaluate.
        #  nixpkgs.config.allowUnsupportedSystem = true;
        #};
        nixosConfigurations.rpi41 = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            sopsDecrypt_ = (nixpkgsFor "x86_64-linux").sopsDecrypt_;
          };
          modules = [
            ({ config, lib, pkgs, resources, ... }: {
              #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
              #nixpkgs.localSystem.system = "x86_64-linux";
              nixpkgs.localSystem.system = "aarch64-linux";
              imports = [
                (import "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
                (import ./hosts/rpi41/configuration.nix)
                outputs.nixosModules.defaults
              ];
              boot.kernelPackages = pkgs.linuxPackages_5_10;
              boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "uas" "usb_storage" ];
              boot.loader.raspberryPi.firmwareConfig = "dtparam=sd_poll_once=on";
              #fileSystems."/".options = [ "defaults" "discard" ];
              services.fstrim.enable = true;

              ##boot.loader.generic-extlinux-compatible.enable = true;
              boot.loader.generic-extlinux-compatible.configurationLimit = 10;
              #boot.loader.raspberryPi.uboot.enable = false;
              #boot.loader.raspberryPi.enable = true;
              #boot.loader.raspberryPi.version = 4;

              nixpkgs.overlays = [
                inputs.nix.overlays.default
                inputs.nur_dguibert.overlays.default
                (final: prev: {
                  # don't build qt5
                  # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
                  pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
                })
                (self: super: lib.optionalAttrs (super.stdenv.hostPlatform != super.stdenv.buildPlatform) {
                  # Restrict drivers built by mesa to just the ones we need This
                  # reduces the install size a bit.
                  mesa = (super.mesa.override {
                    vulkanDrivers = [ ];
                    driDrivers = [ ];
                    galliumDrivers = [ "vc4" "swrast" ];
                    enableRadv = false;
                    withValgrind = false;
                    enableOSMesa = false;
                    enableGalliumNine = false;
                  }).overrideAttrs (o: {
                    mesonFlags = (o.mesonFlags or [ ]) ++ [ "-Dglx=disabled" ];
                  });

                  libcec = super.libcec.override { inherit (super) libraspberrypi; };

                  kodiPlain = (super.kodiPlain.override {
                    vdpauSupport = false;
                    libva = null;
                    raspberryPiSupport = true;
                  });
                })

              ];

              sdImage.compressImage = false;
              documentation.nixos.enable = false;

              hardware.opengl = {
                enable = true;
                setLdLibraryPath = true;
                package = pkgs.mesa.drivers;
              };
              programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";

              sops.defaultSopsFile = ./hosts/rpi41/secrets/secrets.yaml;
            })
          ];
        };
        nixosConfigurations.t580 = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            sopsDecrypt_ = (nixpkgsFor "x86_64-linux").sopsDecrypt_;
          };
          modules = [
            ({ config, lib, pkgs, resources, ... }: {
              nixpkgs.localSystem = {
                #gcc.arch = "skylake"; #kabylake
                #gcc.tune = "skylake"; #kabylake
                system = "x86_64-linux";
              };
              imports = [
                (import ./hosts/t580/configuration.nix)
                outputs.nixosModules.defaults
                outputs.nixosModules.yubikey-gpg-conf
                ({ config, ... }: { yubikey-gpg-conf.enable = true; })
                outputs.nixosModules.x11-conf
                ({ config, ... }: { x11-conf.enable = false; })

                outputs.nixosModules.wayland-conf
                ({ config, ... }: { wayland-conf.enable = true; })
              ];
              sops.defaultSopsFile = ./hosts/t580/secrets/secrets.yaml;
            })
          ];
        };

        deploy.nodes = inputs.nixpkgs.lib.recursiveUpdate
          (inputs.nixpkgs.lib.mapAttrs
            (host: nixosConfig: {
              hostname = "${nixosConfig.config.networking.hostName}";
              profiles.system.path = inputs.deploy-rs.lib.${nixosConfig.config.nixpkgs.localSystem.system}.activate.nixos
                nixosConfig;
              profiles.system.user = "root";
              # Fast connection to the node. If this is true, copy the whole closure instead of letting the node substitute.
              # This defaults to `false`
              fastConnection = true;

              # If the previous profile should be re-activated if activation fails.
              autoRollback = true;

              # See the earlier section about Magic Rollback for more information.
              # This defaults to `true`
              magicRollback = false;

              profiles.hm-dguibert.path = inputs.deploy-rs.lib.${nixosConfig.config.nixpkgs.localSystem.system}.activate.custom
                inputs.self.homeConfigurations.${nixosConfig.config.nixpkgs.localSystem.system}.${host}.dguibert.home.activationPackage
                "./activate";
              profiles.hm-dguibert.user = "dguibert";
            })
            (builtins.removeAttrs inputs.self.nixosConfigurations [ "iso" ]))
          ({ });

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy)
          (inputs.nixpkgs.lib.getAttrs supportedSystems inputs.deploy-rs.lib);

      });
}
