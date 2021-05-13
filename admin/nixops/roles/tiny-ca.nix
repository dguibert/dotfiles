{ config, lib, pkgs, ... }:
let
  cfg = config.roles.tiny-ca;
in
{
  # https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/
  options.roles.tiny-ca = {
    enable = lib.mkOption {
      default = false;
      description = "Wether to enable tiny-ca role";
      type = lib.types.bool;
    };
    openFirewall = lib.mkEnableOption "opening the certificate authority server port";
  };
  # openFirewall

  config = lib.mkIf cfg.enable {
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
            subject.user == "step") {
          return polkit.Result.YES;
        }
      });

      polkit.addRule(function(action, subject) {
        if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
            subject.user == "step") {
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
        ##"ssh": {
        ##  "hostKey": "/tmp/mystep/secrets/ssh_host_ca_key",
        ##  "userKey": "/tmp
        db = {
          type = "badger";
          dataSource = "/var/lib/step-ca/db";
        };
        logger.format = "text";
        authority = {
          provisioners = [
            {
              type = "JWK";
              name = "david.guibert@gmail.com";
              key = {
                use = "sig";
                kty = "EC";
                kid = "_tR4oJYrA7NnS3pLyFmPCXXq4K0LucpIME98E1YGN20";
                crv = "P-256";
                alg = "ES256";
                x = "RizikYmFrTuIkGPGXDKH91dI03OL7_Rer0vwaoy4sjU";
                y = "dVNBlCoPfT4U7VfDUUMo0-m-V4golPrfFf99gBwxmdA";
              };
              encryptedKey = "eyJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1ciLCJjdHkiOiJqd2sranNvbiIsImVuYyI6IkEyNTZHQ00iLCJwMmMiOjEwMDAwMCwicDJzIjoibXJTZnVSNVhsb0l1V0puNHpob3BFQSJ9.E-DhIuoL7zY4dSGzKFCPdtm47uR6lq_J5XGaSC2lgg7H7t_P2of5nQ.Cmjob-x3k60Ttu_a._zpYG-XX8VrWUba4qn1EQJO3WTZ1hJXc70i5xKI4VRKzjgPXhNv7xuHztQWIiyRs9PbC5RufmV3OVeSvLLXGMIY74OXggk0tVGVGqhM0q8i0fcRU2xsvzU8j31nPPMYTHYwrUrqjTX50xgE47bSu08kL-RnKmrLXezTzJHueHrMFGucS3tvXQ2NSPBfZtnJaBwMFkDhosgcTGXGgZTDx5F6GWB2TGk8S9c6xwdiN4BKgOUfbiQcB3irppm_IPoaNUyGsu7iFPkJqr1TTBaVLL79G0B8LGmUrxJfj1pDu2s7i63IrvbPs2m5CMjssGGrBu23jUiP9W9XWSY7oQZg.gGJd1C5k0eZFjmurm2UFWA";
              claims.enableSSHCA = true;
            }
            {
              type = "ACME";
              name = "acme";
            }
            ##{
            ##  "type": "SSHPOP",
            ##  "name": "sshpop",
            ##  "claims": {
            ##    "enableSSHCA": true
            ##  }
            ##},
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
        BindTo=[ "dev-yubikey.device" ];
        after= [ "dev-yubikey.device" ];
      };
      wantedBy = [ "dev-yubikey.device" ];
    };
    ## $ sudo mkdir /etc/systemd/system/dev-yubikey.device.wants
    ## $ sudo ln -s /etc/systemd/system/step-ca.service /etc/systemd/system/dev-yubikey.device.wants/
  };
}
