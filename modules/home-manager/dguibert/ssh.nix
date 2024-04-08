{ lib, ... }:
{
  # ssh -F ssh_config $host -o PubkeyAuthentication=yes -Nf
  # ssh -F ssh_config $host -O check
  # ssh -F ssh_config $host -O exit
  #
  # ssh -F ssh_config $host -O forward -L ....
  # ssh -F ssh_config $host -O cancel -L ....
  programs.ssh =
    let
      matchexec_host = host: ip: port: {
        inherit host port;
        match = "originalhost ${host} Exec \"nc -w 1 -z ${ip} ${toString port} 1>&2 >/dev/null\"";
        hostname = ip;
        proxyCommand = "none";
        extraOptions.HostKeyAlias = host;
      };
      ## https://superuser.com/a/1635657
      home_host = host: ip: port: vpn_ip: mac: {
        ## Coming from localhost.
        "${host}_0" = {
          match = "originalhost ${host} exec \"[ %h = %L ]\"";
          extraOptions.LocalCommand = "echo \"SSH %n: To localhost\" >&2";
        };
        ## Coming from outside home network.
        "${host}_1" = lib.hm.dag.entryAfter [ "${host}_0" ] {
          match = "originalhost ${host} !exec \"[ %h = %L ]\" !exec \" ip neigh | grep REACHABLE | grep -Fw ${mac}\" !exec \"ip route | grep ${vpn_ip}\"";
          extraOptions.LocalCommand = "echo \"SSH %n: From outside network, to %h\" >&2";
          proxyJump = lib.mkIf (host != "rpi41") "rpi41";
          hostname = lib.mkIf (host == "rpi41") "82.64.121.168";
          port = lib.mkIf (host == "rpi41") 443;

        };
        ## Coming from VPN
        "${host}_2" = lib.hm.dag.entryAfter [ "${host}_1" ] {
          match = "originalhost ${host} !exec \"[ %h = %L ]\" !exec \" ip neigh | grep REACHABLE | grep -Fw ${mac}\" exec \"ip route | grep ${vpn_ip}\"";
          extraOptions.PermitLocalCommand = "yes";
          extraOptions.LocalCommand = "echo \"SSH %n: From VPN network, to %h\" >&2";
          proxyCommand = "none";
          hostname = "${vpn_ip}";
          inherit port;
        };
        ## Coming from inside home network.
        "${host}_3" = lib.hm.dag.entryAfter [ "${host}_2" ] {
          host = "${host}";
          extraOptions.PermitLocalCommand = "yes";
          extraOptions.LocalCommand = "echo \"SSH %n: From home network, to %h\" >&2";
          hostname = "${ip}";
          inherit port;
        };
      };
    in
    {
      enable = true;
      compression = true;
      controlMaster = "auto";
      controlPath = "~/.ssh/socket-%C";
      controlPersist = "4h";

      #extraOptionOverrides = ''
      #'';
      extraConfig = ''
        IdentitiesOnly yes
        #IdentityFile id_dsa
        PasswordAuthentication no
        PubkeyAuthentication yes
        TCPKeepAlive yes
      '';

      matchBlocks = {
        "*" = {
          match = "Host * Exec \"test -e ~/.ssh/extra_config\"";
          extraOptions.Include = "~/.ssh/extra_config";
        };
        "127.0.0.1 | localhost" = {
          forwardAgent = true;
          forwardX11 = true;
          forwardX11Trusted = true;
          extraOptions.NoHostAuthenticationForLocalhost = "yes";
        };

      }
      // (home_host "rpi31" "192.168.1.13" 22322 "10.147.27.13" "b8:27:eb:46:86:14")
      // (home_host "rpi41" "192.168.1.14" 22322 "10.147.27.14" "dc:a6:32:67:dd:9f")
      // (home_host "t580" "192.168.1.17" 22322 "10.147.27.17" "d2:b6:17:1d:b8:97")
      // (home_host "titan" "192.168.1.24" 22322 "10.147.27.24" "be:f8:2c:e5:1d:4e")
      ;
    };


}
