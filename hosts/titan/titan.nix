({ config, lib, pkgs, inputs, ... }: {
  imports = [
    inputs.hydra.nixosModules.hydra
    ./configuration.nix
    ../../modules/nixos/defaults
  ];
  #hardware.opengl.extraPackages = [ pkgs.vaapiVdpau /*pkgs.libvdpau-va-gl*/ ];
  environment.systemPackages = [ pkgs.pavucontrol pkgs.ipmitool pkgs.ntfs3g ];

  networking.firewall.checkReversePath = false;

  #systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nix/nix-daemon.secrets.env";

  virtualisation.virtualbox.host.enable = true;
  systemd.network.wait-online.ignoredInterfaces = [ "vboxnet0" ];

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
    secret-key-files = ${config.sops.secrets."cache-priv-key.pem".path}
  '';
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.secrets."cache-priv-key.pem" = { };
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
