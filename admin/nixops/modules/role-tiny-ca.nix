{ config, lib, pkgs, ... }:
let
  cfg = config.role.tiny-ca;
in
{
  # https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/
  options.role.tiny-ca = {
    enable = lib.mkOption {
      default = false;
      description = "Wether to enable tiny-ca role";
      type = lib.types.bool;
    };
    openFirewall = lib.mkEnableOption "opening the certificate authority server port";
  };
  # openFirewall

  config = lib.mkIf cfg.enable {
    ## https://github.com/NixOS/nixpkgs/pull/112322#issuecomment-780810817
    #security.acme.server = "https://localhost:9443/acme/acme/directory";
    #security.acme.email = "david.guibert+acme@gmail.com";
    #security.acme.acceptTerms = true;
    ## security.pki.certificateFiles = [ ../secrets/root-ca.crt ../secrets/intermediate_ca.crt ];
    security.pki.certificateFiles = [
      ../online-ca-orsin/certs/root_ca.crt
      ../online-ca-orsin/certs/intermediate_ca.crt
    ];

    ##networking.hosts = {
    ##  "192.168.1.24" = [ "jellyfin.local" ];
    ##};
    ###services.nginx = {
    ###  enable = true;
    ###  virtualHosts."blog.example.com" = {
    ###    enableACME = true;
    ###    forceSSL = true;
    ###    root = "/var/www/blog";
    ###  };
    ###};
    ##security.acme.acceptTerms = true;
    ##security.acme.email = "david.guibert+certs@gmail.com";
    ##security.acme.server = "https://localhost:9443/acme/acme/directory";
    ##security.acme.validMinDays=1;
    ##security.acme.certs."jellyfin.local" = {
    ##  group = config.users.groups.haproxy.name;
    ##  #extraLegoFlags=[ "--http.port" ":8888" "--tls" "--tls.port" ":8843" ];
    ##  extraLegoFlags=[ "--http.port" ":8888" "--dns.disable-cp" ];
    ##};
    ### extraDomainNames
    ### group
    ### .extraLegoFlags --http-port
    ###security.acme.certs = {
    ###  "blog.example.com".email = "youremail@address.com";
    ###};
    ###https://serversforhackers.com/c/letsencrypt-with-haproxy
    ### sudo certbot certonly --standalone -d demo.scalinglaravel.com \
    ###    --non-interactive --agree-tos --email admin@example.com \
    ###    --http-01-port=8888

    ##networking.firewall.interfaces.bond0.allowedTCPPorts = [
    ##  443 80
    ##];

    ##services.haproxy.enable = true;
    ##services.haproxy.config = ''
    ##  global
    ##          log /dev/log local0 debug

    ##  defaults
    ##      timeout connect 5s
    ##      timeout client 1m
    ##      timeout server 1m

    ##  frontend frontend-http
    ##      bind jellyfin.local:80
    ##      #bind :::80
    ##      mode http
    ##      # ACL for detecting Let's Encrypt validtion requests
    ##      acl is_certbot path_beg /.well-known/acme-challenge/
    ##      redirect scheme https code 301 if !is_certbot
    ##      use_backend letsencrypt_http if is_certbot

    ##  frontend jellyfin_https
    ##      mode http
    ##      #bind jellyfin.local:443 transparent ssl crt /var/lib/acme/jellyfin.local/full.pem ca-file ${../online-ca-orsin/certs/root_ca.crt} verify required alpn h2,http/1.1
    ##      bind jellyfin.local:443 ssl crt /var/lib/acme/jellyfin.local/full.pem ca-file ${../online-ca-orsin/certs/root_ca.crt} verify optional
    ##      # ACL for detecting Let's Encrypt validtion requests
    ##      acl is_certbot path_beg /.well-known/acme-challenge/
    ##      use_backend letsencrypt_http if is_certbot

    ##      default_backend jellyfin

    ##  backend jellyfin
    ##      mode http
    ##      http-request set-header X-Forwarded-Port %[dst_port]
    ##      http-request add-header X-Forwarded-Proto https if { ssl_fc }
    ##      server jellyfin 127.0.0.1:8096

    ##  backend letsencrypt_http
    ##      mode http
    ##      dispatch 127.0.0.1:8888
    ##      #server letsencrypt 127.0.0.1:8888

    ##'';
    #### Renew the certificate
    ###certbot renew --force-renewal --tls-sni-01-port=8888
    #### Concatenate new cert files, with less output (avoiding the use tee and its output to stdout)
    ###bash -c "cat /etc/letsencrypt/live/demo.scalinglaravel.com/fullchain.pem /etc/letsencrypt/live/demo.scalinglaravel.com/privkey.pem > /etc/ssl/demo.scalinglaravel.com/demo.scalinglaravel.com.pem"
    #### Reload  HAProxy
    ###service haproxy reload


    services.udev.extraRules = with pkgs; ''
      ATTR{idProduct}=="0407", ATTR{idVendor}=="1050", TAG+="systemd", SYMLINK="yubikey"
    '';

    # :May 12 14:00:25 titan pcscd[398380]: 05472881 auth.c:137:IsClientAuthorized() Process 402117 (user: 64191) is NOT authorized for action: access_pcsc
    # :May 12 14:00:25 titan pcscd[398380]: 00000146 winscard_svc.c:335:ContextThread() Rejected unauthorized PC/SC client
    # :May 12 14:00:25 titan step-ca[402117]: connecting to pscs: an internal communications error has been detected
    # https://github.com/LudovicRousseau/PCSC/blob/master/doc/README.polkit
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.debian.pcsc-lite.access_card" &&
            subject.user == "step-ca") {
          return polkit.Result.YES;
        }
      });

      polkit.addRule(function(action, subject) {
        if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
            subject.user == "step-ca") {
          return polkit.Result.YES;
        }
      });
    '';

    # https://github.com/NixOS/nixpkgs/pull/112322
    # https://github.com/smallstep/certificates/discussions/529
    ##
    ## Run ykman piv keys generate --algorithm ECCP256 82 ssh_host_ca_key.pem to generate a host key in slot 82 on the YubiKey, and output a public key
    ## Then run ssh-keygen -i -f ssh_host_ca_key.pem -mPKCS8 > ssh_host_ca_key.pub to convert it to SSH public key
    ## Repeat this for the user SSH CA key, using slot 83.
    services.step-ca = {
      enable = true;
      address = "0.0.0.0";
      port = 9443;
      openFirewall = cfg.openFirewall;
      #intermediatePasswordFile = "/etc/nixos/secrets/tiny-ca.passwd";
      settings = /* builtins.fromJSON config/ca.json*/ {
        dnsNames = [
          "localhost"
          "192.168.1.24"
          "10.147.27.24"
        ];
        #root = ../../../secrets/root_ca.crt;
        #crt = ../../../secrets/intermediate_ca.crt;
        #key = ../../../secrets/intermediate_ca.key;
        root = ../online-ca-orsin/certs/root_ca.crt;
        crt = ../online-ca-orsin/certs/intermediate_ca.crt;
        key = "yubikey:slot-id=9c";
        kms = {
          type = "yubikey";
          pin = "123456";
        };
        ssh = {
          hostKey = "yubikey:slot-id=82";
          userKey = "yubikey:slot-id=83";
        };
        db = {
          type = "badger";
          dataSource = "/var/lib/step-ca/db";
        };
        logger.format = "text";
        authority = {
          provisioners = [
            {
              type = "OIDC";
              name = "Google";
              clientID = "811353294591-gv6ma78sa72vaiap6qmak2cqgq1sleqb.apps.googleusercontent.com";
              clientSecret = pkgs.sopsDecrypt_ ../secrets/defaults.yaml "orsin-ca-811353294591-gv6ma78sa72vaiap6qmak2cqgq1sleqb.apps.googleusercontent.com";
              configurationEndpoint = "https://accounts.google.com/.well-known/openid-configuration";
              admins = [ "david.guibert@gmail.com" ];
              domains = [ "gmail.com" ];
              claims.enableSSHCA = true;
            }
            {
              type = "ACME";
              name = "acme";
              claims = {
                maxTLSCertDuration = "2160h";
                defaultTLSCertDuration = "2160h";
              };
            }
            {
              type = "SSHPOP";
              name = "sshpop";
              claims.enableSSHCA = true;
            }
          ];
        };
        tls = {
          cipherSuites = [
            "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
            "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
          ];
          minVersion = 1.2;
          maxVersion = 1.3;
          renegotiation = false;
        };
      };
    };

    systemd.services."step-ca" = {
      #[Unit]
      unitConfig = {
        BindTo = [ "dev-yubikey.device" ];
      };
      after = [ "dev-yubikey.device" ];
      wantedBy = [ "dev-yubikey.device" ];
    };
    ## $ sudo mkdir /etc/systemd/system/dev-yubikey.device.wants
    ## $ sudo ln -s /etc/systemd/system/step-ca.service /etc/systemd/system/dev-yubikey.device.wants/
  };
}
