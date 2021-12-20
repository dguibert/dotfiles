{
  description = "Configurations of my systems";


  # To update all inputs:
  # $ nix flake update --recreate-lock-file
  inputs = {
    home-manager. url    = "github:dguibert/home-manager/pu";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hydra.url            = "github:dguibert/hydra/pu";
    hydra.inputs.nix.follows = "nix";
    hydra.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url          = "github:dguibert/nixpkgs/pu";

    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    sops-nix.url = "github:Mic92/sops-nix";
    #sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nur_dguibert.url     = "github:dguibert/nur-packages/master";
    nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
    nur_dguibert.inputs.nix.follows = "nix";
    nur_dguibert.inputs.flake-utils.follows = "flake-utils";
    #nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
    #nur_dguibert_envs.url= "git+file:///home/dguibert/nur-packages?dir=envs";
    #nur_dguibert_envs.inputs.nixpkgs.follows = "nixpkgs";
    #nur_dguibert_envs.inputs.nix.follows     = "nix";
    terranix             = { url = "github:mrVanDalo/terranix"; flake=false; };
    #"nixos-18.03".url   = "github:nixos/nixpkgs-channels/nixos-18.03";
    #"nixos-18.09".url   = "github:nixos/nixpkgs-channels/nixos-18.09";
    #"nixos-19.03".url   = "github:nixos/nixpkgs-channels/nixos-19.03";
    base16-nix           = { url  = "github:dguibert/base16-nix"; flake=false; };
    gitignore            = { url  = "github:hercules-ci/gitignore"; flake=false; };

    nxsession.url           = "github:dguibert/nxsession";
    nxsession.inputs.nixpkgs.follows = "nixpkgs";
    nxsession.inputs.flake-utils.follows = "flake-utils";

    dwm-src.url = "github:dguibert/dwm/pu";        dwm-src.flake = false;
    st-src.url  = "github:dguibert/st/pu";         st-src.flake = false;

    # For accessing `deploy-rs`'s utility Nix functions
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-wayland.url = "github:colemickens/nixpkgs-wayland";
    # only needed if you use as a package set:
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    #nixpkgs-wayland.inputs.master.follows = "master";
  };

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs: let
      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = system:
        import inputs.nixpkgs {
          inherit system;
          overlays =  [
            inputs.nix.overlay
            inputs.nur.overlay
            inputs.nur_dguibert.overlay
            inputs.nur_dguibert.overlays.extra-builtins
            #nur_dguibert_envs.overlay
            inputs.self.overlay
            inputs.nxsession.overlay
          ];
          config.allowUnfree = true;
          #config.contentAddressedByDefault = true;
        };

      inherit (nixpkgsFor "x86_64-linux")
        sopsDecrypt_
        wgPubKey_
        extra_builtins_file;

  in (inputs.flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux" ] (system:
       let pkgs = nixpkgsFor system; in rec {

    devShell = pkgs.callPackage ./shell.nix { inherit inputs;
      inherit (inputs.sops-nix.packages.${system}) sops-import-keys-hook ssh-to-pgp;
      deploy-rs = inputs.deploy-rs.packages.${system}.deploy-rs;
    };
    legacyPackages = pkgs;

    homeConfigurations = inputs.nixpkgs.lib.genAttrs
      (builtins.attrNames (builtins.removeAttrs inputs.self.nixosConfigurations ["iso" ]))
          (host: inputs.self.nixosConfigurations.${host}.config.home-manager.users) // {
    };

  })) // (rec {
    overlay = final: prev: with final; {
      # Patch libvirt to use ebtables-legacy
      libvirt = if prev.libvirt.version <= "5.4.0" && prev.ebtables.version > "2.0.10-4"
        then
          prev.libvirt.overrideAttrs (oldAttrs: rec {
            EBTABLES_PATH="${final.ebtables}/bin/ebtables-legacy";
          })
        else prev.libvirt;

      install-script = drv: with final; writeScript "install-${drv.name}"
      ''#!/usr/bin/env bash
        set -x

        nixos-install --system ${drv} $@

        umount -R /mnt
        zfs set mountpoint=legacy bt580/nixos
        zfs set mountpoint=legacy rt580/tmp
      '';

      dwm = prev.dwm.overrideAttrs (o: {
        src = inputs.dwm-src;
        patches = [];
      });
      st = prev.st.overrideAttrs (o: {
        src = inputs.st-src;
        patches = [];
      });
    };

    ## - hydraJobs: A nested set of derivations built by Hydra.
    ##
    ## -
    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosModules.defaults = { config, lib, pkgs, resources, ...}: {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops

        ./modules/wireguard-mesh.nix
        ./modules/report-changes.nix

        (import ./roles/robotnix-ota.nix)
        (import ./roles/tiny-ca.nix { inherit sopsDecrypt_; })
        ./roles/mopidy.nix
        ./roles/sshguard.nix
        ./roles/wireguard-mesh.nix

        (import ./users/default.nix { inherit sopsDecrypt_ pkgs inputs; })
      ];

      system.nixos.versionSuffix = lib.mkForce
        ".${lib.substring 0 8 (inputs.self.lastModifiedDate or inputs.self.lastModified or "19700101")}.${inputs.self.shortRev or "dirty"}";
      system.nixos.revision = lib.mkIf (inputs.self ? rev) (lib.mkForce inputs.self.rev);
      nixpkgs.config = pkgs: (import "${inputs.nur_dguibert}/config.nix" pkgs) // {
        permittedInsecurePackages = [
          "ffmpeg-3.4.8" # oraclejre
        ];
      };
      nixpkgs.overlays = [
        inputs.nix.overlay
        inputs.nur.overlay
        inputs.nur_dguibert.overlay
        inputs.nur_dguibert.overlays.extra-builtins
        inputs.nur_dguibert.overlays.emacs
        #nur_dguibert_envs.overlay
        inputs.self.overlay
        inputs.nxsession.overlay
      ];
      # TODO understand why it's necessary instead of default pkgs.nix (nix build: OK, nixops: KO)
      nix.package = inputs.nix.defaultPackage."${config.nixpkgs.localSystem.system}";
      nix.registry = lib.mapAttrs (id: flake: {
        inherit flake;
        from = { inherit id; type = "indirect"; };
      }) inputs;
      environment.shellInit = ''
        export NIX_PATH=nixpkgs=${inputs.nixpkgs}:nur_dguibert=${inputs.nur_dguibert}
        NIX_OPTIONS=()
        NIX_OPTIONS+=("--option extra-builtins-file ${extra_builtins_file}")
        export NIX_OPTIONS
      '';
      nix.systemFeatures = [ "recursive-nix" ] ++ # default
        [ "nixos-test" "benchmark" "big-parallel" "kvm" ] ++
	lib.optionals (config.nixpkgs ? localSystem && config.nixpkgs.localSystem ? system) [
	  "gccarch-${builtins.replaceStrings ["_"] ["-"] (builtins.head (builtins.split "-" config.nixpkgs.localSystem.system))}"
	] ++
        lib.optionals (pkgs.hostPlatform ? gcc.arch) (
          # a builder can run code for `gcc.arch` and inferior architectures
          [ "gccarch-${pkgs.hostPlatform.gcc.arch}" ] ++
          map (x: "gccarch-${x}") lib.systems.architectures.inferiors.${pkgs.hostPlatform.gcc.arch}
        );

      programs.gnupg.agent.pinentryFlavor = "gtk2";

      roles.wireguard-mesh.enable = true;
      # System wide: echo "@cert-authority * $(cat /etc/ssh/ca.pub)" >>/etc/ssh/ssh_known_hosts
      programs.ssh.knownHosts."*" = {
        certAuthority=true;
        publicKey = builtins.readFile ./secrets/ssh-ca-home.pub;
      };

      sops.secrets.id_buildfarm = {
        sopsFile = ./secrets/defaults.yaml;
        owner = "root";
        path = "/etc/nix/id_buildfarm";
      };

      # don't set ssh_host_rsa_key since userd by sops to decrypt secrets
      #sops.secrets."ssh_host_rsa_key"              .path = "/persist/etc/ssh/ssh_host_rsa_key";
      sops.secrets."ssh_host_rsa_key.pub"          .path = "/persist/etc/ssh/ssh_host_rsa_key.pub";
      sops.secrets."ssh_host_rsa_key-cert.pub"     .path = "/persist/etc/ssh/ssh_host_rsa_key-cert.pub";
      #sops.secrets."ssh_host_ed25519_key"          .path = "/persist/etc/ssh/ssh_host_ed25519_key";
      sops.secrets."ssh_host_ed25519_key.pub"      .path = "/persist/etc/ssh/ssh_host_ed25519_key.pub";
      sops.secrets."ssh_host_ed25519_key-cert.pub" .path = "/persist/etc/ssh/ssh_host_ed25519_key-cert.pub";

      services.openssh.extraConfig = lib.mkOrder 100 ''
        HostCertificate ${config.sops.secrets."ssh_host_ed25519_key-cert.pub".path}
        HostCertificate ${config.sops.secrets."ssh_host_rsa_key-cert.pub".path}
      '';
      services.openssh.hostKeys = [
        {
	  #path = config.sops.secrets."ssh_host_ed25519_key".path;
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];

      report-changes.enable = true;
    };

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
    #        inputs.self.nixosModules.defaults
    #        (import ./hosts/orsine/configuration.nix)
    #      ];
    #    })
    #  ];
    #};


    ## nix build .#nixosConfigurations.iso.config.system.build.isoImage
    nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        (import "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
        ./modules/zfs.nix
        ./hosts/iso.nix
        ({ config, lib, pkgs, resources, ... }: {
          nixpkgs.localSystem.system = "x86_64-linux";
        })
        ({ ... }: {
          networking.wireless.interfaces = [ "wlan0" ];
        })
      ];
    };

    nixosConfigurations.titan = inputs.nixpkgs.lib.nixosSystem {
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
            inputs.self.nixosModules.defaults
            ./modules/yubikey-gpg.nix
            ./modules/distributed-build.nix
            ./modules/x11.nix
          ];
          hardware.opengl.enable = true;
          hardware.opengl.extraPackages = [ pkgs.vaapiVdpau pkgs.libvdpau-va-gl ];

          hardware.pulseaudio.enable = true;
          # https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Laggy_sound
          hardware.pulseaudio.daemon.config.default-fragments = "5";
          hardware.pulseaudio.daemon.config.default-fragment-size-msec = "2";
          environment.systemPackages = [ pkgs.pavucontrol pkgs.ipmitool pkgs.ntfs3g ];

          # https://nixos.org/nixops/manual/#idm140737318329504
          #virtualisation.libvirtd.enable = true;
          #virtualisation.anbox.enable = true;
          #services.nfs.server.enable = true;
          #virtualisation.docker.enable = true;
          #virtualisation.docker.storageDriver = "zfs";

          programs.singularity.enable = true;

          networking.firewall.checkReversePath = false;
          systemd.tmpfiles.rules = lib.mkIf config.virtualisation.libvirtd.enable [ "d /var/lib/libvirt/images 1770 root libvirtd -" ];

          programs.adb.enable = true;

          services.jellyfin.enable = true;
          systemd.services.jellyfin = lib.mkIf config.services.jellyfin.enable {
            serviceConfig.PrivateUsers = lib.mkForce false;
            serviceConfig.PermissionsStartOnly = true;
            preStart = ''
              set -x
              ${pkgs.acl}/bin/setfacl -m user:jellyfin:x /home/dguibert/ || true
              ${pkgs.acl}/bin/setfacl -m user:jellyfin:x /home/dguibert/Videos || true
              ${pkgs.acl}/bin/setfacl -m user:jellyfin:rx /home/dguibert/Videos/Series || true
              ${pkgs.acl}/bin/setfacl -m user:jellyfin:rx /home/dguibert/Videos/Movies || true
              ${pkgs.acl}/bin/setfacl -m group:jellyfin:x /home/dguibert/ || true
              ${pkgs.acl}/bin/setfacl -m group:jellyfin:x /home/dguibert/Videos || true
              ${pkgs.acl}/bin/setfacl -m group:jellyfin:rx /home/dguibert/Videos/Series || true
              ${pkgs.acl}/bin/setfacl -m group:jellyfin:rx /home/dguibert/Videos/Movies || true
              set +x
            '';
            unitConfig.RequiresMountsFor = "/home/dguibert/Videos";
          };
          networking.firewall.interfaces."bond0".allowedTCPPorts = [
            8096 /*http*/ 8920 /*https*/
              config.services.step-ca.port
          ];

          systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nix/nix-daemon.secrets.env";

          roles.mopidy-server.enable = true;
          roles.mopidy-server.listenAddress = "192.168.1.24";
          roles.mopidy-server.configuration.local.media_dir = "/home/dguibert/Music/mopidy";
	  roles.mopidy-server.configuration.m3u = {
	    enabled = true;
	    playlists_dir = "/home/dguibert/Music/playlists";
            base_dir = config.roles.mopidy-server.configuration.local.media_dir;
            default_extension = ".m3u8";
          };
          roles.mopidy-server.configuration.local.scan_follow_symlinks = true;
          roles.mopidy-server.configuration.iris.country = "FR";
          roles.mopidy-server.configuration.iris.locale = "FR";

          roles.tiny-ca.enable = true;
          services.step-ca.intermediatePasswordFile = config.sops.secrets.orsin-ca-intermediatePassword.path;
          sops.secrets.orsin-ca-intermediatePassword = {
            sopsFile = ./secrets/defaults.yaml;
          };
          roles.robotnix-ota-server.enable = true;
          roles.robotnix-ota-server.openFirewall = true;

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
      modules = [
        ({ config, lib, pkgs, resources, ... }: {
          #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
          #nixpkgs.localSystem.system = "x86_64-linux";
          nixpkgs.localSystem.system = "aarch64-linux";
          imports = [
            (import "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
            (import ./hosts/rpi31/configuration.nix)
            inputs.self.nixosModules.defaults
          ];
          nixpkgs.overlays = [
            inputs.nix.overlay
            inputs.nur_dguibert.overlays.default
            (final: prev: {
              # don't build qt5
              # enabledFlavors ? [ "curses" "tty" "gtk2" "qt" "gnome3" "emacs" ]
              pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
            })
          ];

          documentation.nixos.enable = false;
	  #fileSystems."/".options = [ "defaults" "discard" ];

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
          sops.secrets.shadowsocks = {};
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
      modules = [
        ({ config, lib, pkgs, resources, ... }: {
          #nixpkgs.crossSystem = lib.systems.elaborate lib.systems.examples.aarch64-multiplatform;
          #nixpkgs.localSystem.system = "x86_64-linux";
          nixpkgs.localSystem.system = "aarch64-linux";
          imports = [
            (import "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
            (import ./hosts/rpi41/configuration.nix)
            inputs.self.nixosModules.defaults
          ];
          boot.kernelPackages = pkgs.linuxPackages_latest;
	  boot.initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
	  boot.loader.raspberryPi.firmwareConfig = "dtparam=sd_poll_once=on";
	  #fileSystems."/".options = [ "defaults" "discard" ];

          boot.loader.generic-extlinux-compatible.enable = true;
          boot.loader.generic-extlinux-compatible.configurationLimit = 10;
          boot.loader.raspberryPi.uboot.enable = true;
          boot.loader.raspberryPi.enable = true;
          boot.loader.raspberryPi.version = 4;

          nixpkgs.overlays = [
            inputs.nix.overlay
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
                vulkanDrivers = [];
                driDrivers = [];
                galliumDrivers = ["vc4" "swrast"];
                enableRadv = false;
                withValgrind = false;
                enableOSMesa = false;
                enableGalliumNine = false;
              }).overrideAttrs (o: {
                mesonFlags = (o.mesonFlags or []) ++ ["-Dglx=disabled"];
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
            package = pkgs.mesa_drivers;
          };
          programs.gnupg.agent.pinentryFlavor = lib.mkForce "curses";

          sops.defaultSopsFile = ./hosts/rpi41/secrets/secrets.yaml;
        })
      ];
    };
    nixosConfigurations.t580 = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        ({ config, lib, pkgs, resources, ... }: {
          nixpkgs.localSystem = {
	    #gcc.arch = "skylake"; #kabylake
	    #gcc.tune = "skylake"; #kabylake
            system = "x86_64-linux";
          };
          imports = [
            (import ./hosts/t580/configuration.nix)
            inputs.self.nixosModules.defaults
            #({ ... }: {
            #  nix = {
            #    # add binary caches
            #    binaryCachePublicKeys = [
            #      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
            #    ];
            #    binaryCaches = [
            #      "https://nixpkgs-wayland.cachix.org"
            #    ];
            #  };
            #  #specialisation.wayland = { inheritParentConfig = true; configuration = {
            #      services.xserver.enable = lib.mkForce false;
            #      # use it as an overlay
            #      nixpkgs.overlays = [ nixpkgs-wayland.overlay ];
            #      programs.sway = {
            #        enable = true;
            #        wrapperFeatures.gtk = true; # so that gtk works properly
            #        extraPackages = with pkgs; [
            #          swaylock
            #          swayidle
            #          wl-clipboard
            #          mako # notification daemon
            #          alacritty # Alacritty is the default terminal in the config
            #          dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native

            #          waypipe
            #          grim
            #          slurp
            #          wayvnc
            #        ];
            #      };
            #  #  };
            #  #};
            #})
          ];
          sops.defaultSopsFile = ./hosts/t580/secrets/secrets.yaml;
        })
      ];
    };

    deploy.nodes = inputs.nixpkgs.lib.recursiveUpdate (inputs.nixpkgs.lib.mapAttrs (host: nixosConfig: {
      hostname = "${nixosConfig.config.networking.hostName}";
      profiles.system.path = inputs.deploy-rs.lib.${nixosConfig.config.nixpkgs.localSystem.system}.activate.nixos
        nixosConfig;
      profiles.system.user = "root";
      fastConnection = true;
      profiles.hm-dguibert.path = inputs.deploy-rs.lib.${nixosConfig.config.nixpkgs.localSystem.system}.activate.custom
        inputs.self.homeConfigurations.${nixosConfig.config.nixpkgs.localSystem.system}.${host}.dguibert.home.activationPackage
        "./activate";
      profiles.hm-dguibert.user = "dguibert";
    }) (builtins.removeAttrs inputs.self.nixosConfigurations ["iso" ]))
    ({
    });

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;

  });
}
