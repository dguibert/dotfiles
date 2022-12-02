{ config, lib, pkgs, resources, inputs, outputs, ... }: {
  imports = [
    inputs.nixpkgs.nixosModules.notDetected
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = false;
      home-manager.extraSpecialArgs.inputs = inputs;
      home-manager.extraSpecialArgs.outputs = outputs;
    }
    inputs.sops-nix.nixosModules.sops

    outputs.nixosModules.distributed-build-conf
    ({ config, ... }: { distributed-build-conf.enable = true; })
    outputs.nixosModules.nix-conf
    ({ config, ... }: { nix-conf.enable = true; })
    outputs.nixosModules.report-changes

    outputs.nixosModules.role-dns
    outputs.nixosModules.role-sshguard
    outputs.nixosModules.role-wireguard-mesh

    outputs.nixosModules.services

    ../../users/default.nix

    ({ ... }: { documentation.nixos.enable = false; })
    ({ ... }: { programs.mosh.enable = true; })
  ];

  system.nixos.versionSuffix = lib.mkForce
    ".${lib.substring 0 8 (inputs.self.lastModifiedDate or inputs.self.lastModified or "19700101")}.${inputs.self.shortRev or "dirty"}";
  system.nixos.revision = lib.mkIf (inputs.self ? rev) (lib.mkForce inputs.self.rev);
  nixpkgs.config = pkgs: (import "${inputs.nur_dguibert}/config.nix" pkgs) // {
    # https://nixos.wiki/wiki/Chromium
    chromium.commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
  };
  nixpkgs.overlays = [
    inputs.nix.overlays.default
    inputs.emacs-overlay.overlay
    #inputs.nixpkgs-wayland.overlay
    inputs.nur.overlay
    inputs.nur_dguibert.overlay
    inputs.nur_dguibert.overlays.extra-builtins
    inputs.nur_dguibert.overlays.emacs
    #nur_dguibert_envs.overlay
    inputs.nxsession.overlay
    inputs.self.overlays.default
  ];
  ### TODO understand why it's necessary instead of default pkgs.nix (nix build: OK, nixops: KO)
  nix.package = inputs.nix.packages."${config.nixpkgs.localSystem.system}".default;
  nix.registry = lib.mapAttrs
    (id: flake: {
      inherit flake;
      from = { inherit id; type = "indirect"; };
    })
    inputs;
  nix.settings.system-features = [ "recursive-nix" ] ++ # default
    [ "nixos-test" "benchmark" "big-parallel" "kvm" ] ++
    lib.optionals (config.nixpkgs ? localSystem && config.nixpkgs.localSystem ? system) [
      "gccarch-${builtins.replaceStrings ["_"] ["-"] (builtins.head (builtins.split "-" config.nixpkgs.localSystem.system))}"
    ] ++
    lib.optionals (pkgs.hostPlatform ? gcc.arch) (
      # a builder can run code for `gcc.arch` and inferior architectures
      [ "gccarch-${pkgs.hostPlatform.gcc.arch}" ] ++
        map (x: "gccarch-${x}") lib.systems.architectures.inferiors.${pkgs.hostPlatform.gcc.arch}
    );

  environment.systemPackages = [ pkgs.vim pkgs.git ];
  # Select internationalisation properties.
  console.font = "Lat2-Terminus16";
  console.keyMap = lib.mkDefault "fr";
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  programs.gnupg.agent.pinentryFlavor = "gtk2";

  role.wireguard-mesh.enable = true;
  # System wide: echo "@cert-authority * $(cat /etc/ssh/ca.pub)" >>/etc/ssh/ssh_known_hosts
  programs.ssh.knownHosts."*" = {
    certAuthority = true;
    publicKey = builtins.readFile ../../secrets/ssh-ca-home.pub;
  };

  sops.secrets.id_buildfarm = {
    sopsFile = ../../secrets/defaults.yaml;
    owner = "root";
    path = "/etc/nix/id_buildfarm";
  };

  services.openssh.enable = true;
  services.openssh.listenAddresses = [
    { addr = "0.0.0.0"; port = 22322; }
  ];
  networking.firewall.allowedTCPPorts = [ 22322 ];
  services.openssh.startWhenNeeded = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.extraConfig = ''
    HostCertificate ${config.sops.secrets."ssh_host_ed25519_key-cert.pub".path}
    HostCertificate ${config.sops.secrets."ssh_host_rsa_key-cert.pub".path}

    AcceptEnv COLORTERM
    Ciphers chacha20-poly1305@openssh.com,aes256-cbc,aes256-gcm@openssh.com,aes256-ctr
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    MACs umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
  '';

  # don't set ssh_host_rsa_key since userd by sops to decrypt secrets
  #sops.secrets."ssh_host_rsa_key"              .path = "/persist/etc/ssh/ssh_host_rsa_key";
  sops.secrets."ssh_host_rsa_key.pub"          .path = "/persist/etc/ssh/ssh_host_rsa_key.pub";
  sops.secrets."ssh_host_rsa_key-cert.pub"     .path = "/persist/etc/ssh/ssh_host_rsa_key-cert.pub";
  #sops.secrets."ssh_host_ed25519_key"          .path = "/persist/etc/ssh/ssh_host_ed25519_key";
  sops.secrets."ssh_host_ed25519_key.pub"      .path = "/persist/etc/ssh/ssh_host_ed25519_key.pub";
  sops.secrets."ssh_host_ed25519_key-cert.pub" .path = "/persist/etc/ssh/ssh_host_ed25519_key-cert.pub";

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
}
