{ config, lib, pkgs, inputs, outputs, ... }: {
  nixpkgs.localSystem = {
    #gcc.arch = "broadwell"; #E5-2690v4
    #gcc.tune = "broadwell";
    system = "x86_64-linux";
  };
  imports = [
    inputs.hydra.nixosModules.hydra
    (import ./configuration.nix)
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
    sopsFile = ../../secrets/defaults.yaml;
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
  sops.defaultSopsFile = ./secrets/secrets.yaml;
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
}
