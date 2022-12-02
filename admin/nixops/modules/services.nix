{ config, lib, inputs, outputs, ... }:

let
  cfg = config.empty;

  distribution = with outputs.nixosConfigurations; {
    # 443: shadowsocks+ssh
    haproxy = [ rpi31 ];
    adb = [ titan t580 ];
    jellyfin = [ titan ];
    role-libvirtd = [ titan ];
    role-tinyca = [ titan ];
    role-robotnix-ota-server = [ titan ];
    role-mopidy = [ ];
    desktop = [ titan t580 ];
  };

  dispatch_on = hosts: builtins.any (x: x.config.networking.hostName == config.networking.hostName) hosts;
in
{
  imports = [
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.haproxy) {
      networking.firewall.allowedTCPPorts = [ 443 ];
      services.haproxy.enable = true;
      ### https://datamakes.com/2018/02/17/high-intensity-port-sharing-with-haproxy/
      services.haproxy.config = ''
        defaults
          log  global
          mode tcp
          timeout connect 10s
          timeout client 36h
          timeout server 36h
        global
          log /dev/log  local0 debug

        frontend ssl
          mode tcp
          log global
          option tcplog
          bind 0.0.0.0:443
          tcp-request inspect-delay 3s
          tcp-request content accept if { req.ssl_hello_type 1 }

          acl    ssh_payload        payload(0,7)    -m bin 5353482d322e30
          #acl valid_payload req.payload(0,7) -m str "SSH-2.0"
          #tcp-request content reject if !valid_payload
          #tcp-request content accept if { req_ssl_hello_type 1 }

          use_backend openssh            if ssh_payload
          use_backend openssh            if !{ req.ssl_hello_type 1 } { req.len 0 }
          use_backend shadowsocks        if !{ req.ssl_hello_type 1 } !{ req.len 0 }

        backend openssh
          mode tcp
          server openssh 127.0.0.1:22
        backend shadowsocks
          mode tcp
          server socks 127.0.0.1:${toString config.services.shadowsocks.port}

        frontend ssl_t
          mode tcp
          log global
          option tcplog
          bind 0.0.0.0:4443
          tcp-request inspect-delay 3s
          tcp-request content accept if { req.ssl_hello_type 1 }

          acl    ssh_payload        payload(0,7)    -m bin 5353482d322e30

          use_backend openssh_t          if ssh_payload
          use_backend openssh_t          if !{ req.ssl_hello_type 1 } { req.len 0 }
          use_backend shadowsocks        if !{ req.ssl_hello_type 1 } !{ req.len 0 }

        backend openssh_t
          mode tcp
          source 0.0.0.0 usesrc clientip
          server openssh 127.0.0.1:44322
      '';
      # Enable the OpenSSH daemon.
      services.openssh.enable = true;
      services.openssh.listenAddresses = [
        { addr = "127.0.0.1"; port = 44322; }
      ];

      #echo -n "ss://"`echo -n chacha20-ietf-poly1305:$(sops --extract '["shadowsocks"]' -d hosts/rpi31/secrets/secrets.yaml)@$(curl -4 ifconfig.io):443 | base64` | qrencode -t UTF8
      sops.secrets.shadowsocks.sopsFile = ../hosts/rpi31/secrets/secrets.yaml;
      services.shadowsocks = {
        enable = true;
        localAddress = [ "127.0.0.1" ];
        port = 8388;
        passwordFile = config.sops.secrets.shadowsocks.path;
      };


    })
    # adb
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.adb) {
      programs.adb.enable = true;
    })
    # jellyfin
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.jellyfin) {
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

    })
    # role-libvirtd
    outputs.nixosModules.role-libvirtd
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.role-libvirtd) {
      # https://nixos.org/nixops/manual/#idm140737318329504
      role.libvirtd.enable = true;
      #virtualisation.anbox.enable = true;
      #services.nfs.server.enable = true;
      virtualisation.docker.enable = true;
      virtualisation.docker.storageDriver = "zfs";

      programs.singularity.enable = true;
    })
    # role-tinyca
    outputs.nixosModules.role-tiny-ca
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.role-tinyca) {
      role.tiny-ca.enable = true;
      services.step-ca.intermediatePasswordFile = config.sops.secrets.orsin-ca-intermediatePassword.path;
      sops.secrets.orsin-ca-intermediatePassword = {
        sopsFile = ../secrets/defaults.yaml;
      };
      networking.firewall.interfaces."bond0".allowedTCPPorts = [
        config.services.step-ca.port
      ];
    })
    # role-robotnix-ota-server
    outputs.nixosModules.role-robotnix-ota
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.role-robotnix-ota-server) {
      role.robotnix-ota-server.enable = true;
      role.robotnix-ota-server.openFirewall = true;
    })
    # mopidy-server
    outputs.nixosModules.role-mopidy
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.role-mopidy) {
      role.mopidy-server.enable = true; # TODO migrate to pipewire
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
    })
    outputs.nixosModules.wayland-conf
    outputs.nixosModules.yubikey-gpg-conf
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.desktop) {
      wayland-conf.enable = true;
      yubikey-gpg-conf.enable = true;
    })
  ];
}
