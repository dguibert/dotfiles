{ config, lib, inputs, outputs, ... }:

let
  cfg = config.empty;

  distribution = {
    # 443: shadowsocks+ssh
    haproxy = [ outputs.nixosConfigurations.rpi31 ];
  };

  dispatch_on = hosts: builtins.any (x: x.config.networking.hostName == config.networking.hostName) hosts;
in
{
  imports = [
    ({ config, lib, pkgs, inputs, outputs, ... }: lib.mkIf (dispatch_on distribution.haproxy) {
      networking.firewall.allowedTCPPorts = [ 443 22322 2222 ];
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
          server openssh 127.0.0.1:22
      '';
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
  ];
}
