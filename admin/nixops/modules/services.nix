{ config, lib, ... }:

let
  cfg = config.empty;
in
{
  imports = [
    # 443: shadowsocks+ssh
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (config.networking.hostName == "rpi31") {

      networking.firewall.allowedTCPPorts = [ 443 22322 2222 ];
      #networking.firewall.allowedTCPPorts = [ config.services.sslh.port 22322 ];
      #systemd.services.sslh.serviceConfig.User=lib.mkForce "root";
      #services.sslh = {
      #  enable=true;
      #  verbose=true;
      #  transparent=true;
      #  port=443;
      #  ##  { name: "openvpn"; host: "localhost"; port: "1194"; probe: "builtin"; },
      #  ##  { name: "xmpp"; host: "localhost"; port: "5222"; probe: "builtin"; },
      #  ##  { name: "http"; host: "localhost"; port: "80"; probe: "builtin"; },
      #  ##  { name: "tls"; host: "localhost"; port: "443"; probe: "builtin"; },
      #  appendConfig=''
      #    protocols:
      #    (
      #      { name: "ssh"; service: "ssh"; host: "localhost"; port: "22"; probe: "builtin"; },
      #      { name: "anyprot"; host: "localhost"; port: "${toString config.services.shadowsocks.port}"; probe: "builtin"; }
      #    );
      #  '';
      #};
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

        frontend ssh_t
          mode tcp
          bind 0.0.0.0:2222 transparent
        backend openssh_t
          mode tcp
          source 0.0.0.0 usesrc clientip
          server openssh 127.0.0.1:22
      '';
      # https://www.nginx.com/blog/running-non-ssl-protocols-over-ssl-port-nginx-1-15-2/
      #services.nginx.enable = true;
      #services.nginx.streamConfig = ''
      #  upstream ssh {
      #    server 127.0.0.1:22;
      #  }

      #  upstream shadowsocks {
      #    server 127.0.0.1:${toString config.services.shadowsocks.port};
      #  }

      #  map $ssl_preread_protocol $upstream {
      #    "" ssh;
      #    "TLSv1*"   shadowsocks;
      #    default    shadowsocks;
      #  }

      #  # SSH and SSL on the same port
      #  server {
      #    listen 443;

      #    proxy_pass $upstream;
      #    ssl_preread on;
      #  }
      #'';

      # Enable the OpenSSH daemon.
      services.openssh.enable = true;
      services.openssh.listenAddresses = [
        { addr = "127.0.0.1"; port = 22; }
        { addr = "0.0.0.0"; port = 22322; }
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
    ({ config, lib, pkgs, inputs, outputs, ... }: {
      imports = [ ];
    })
  ];
}
