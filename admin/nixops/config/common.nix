{ config, pkgs, lib, ... }:
{
  boot.consoleLogLevel = 6; #KERN_INFO
  environment.systemPackages = [ pkgs.vim ];
  # Select internationalisation properties.
  i18n = {
     consoleFont = "Lat2-Terminus16";
     consoleKeyMap = "fr";
     defaultLocale = "en_US.UTF-8";
   };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  users.mutableUsers = false;

  # Enable ZeroTierOne
  services.zerotierone.enable = false;
  services.zerotierone.joinNetworks = [ "e5cd7a9e1cd44c48" ];

  networking.useNetworkd = true;
  services.resolved.extraConfig="DNS=8.8.8.8";
  systemd.network.enable = true;
  # https://github.com/NixOS/nixpkgs/issues/18962
  # Prevent networkd from managing unconfigured links.
  #systemd.network.networks."99-main".enable = false;
  #networking.resolvconf.dnsExtensionMechanism=false; #disable the edns0 option in resolv.conf. (most popular user of that feature is DNSSEC)
  services.nscd.enable = false; # no real gain (?) on workstations
  # unreachable DNS entries from home
  networking.hosts = {
    "209.51.188.200" = [ "ftpmirror.gnu.org" ];
    "209.51.188.201" = [ "git.savannah.gnu.org" ];
  };

  # disnix target
  dysnomia.properties.mem = "$(grep 'MemTotal:' /proc/meminfo | sed -e 's/kB//' -e 's/MemTotal://' -e 's/ //g')";
  dysnomia.properties.disks = "$(ls /dev/disk/by-id/ | grep -v -- '-part.*' | tr '\\\\n' ' ')";
  # https://hydra.nixos.org/job/disnix/disnix-trunk/tarball/latest/download-by-type/doc/manual/#chap-packages
  environment.variables.PATH = [ "/nix/var/nix/profiles/disnix/default/bin" ];

  services.openssh.startWhenNeeded = true;
  services.openssh.passwordAuthentication = false;
  # https://www.sweharris.org/post/2016-10-30-ssh-certs/
  # http://www.lorier.net/docs/ssh-ca
  # https://linux-audit.com/granting-temporary-access-to-servers-using-signed-ssh-keys/
  users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEX3tOUaRwa9tVXn7GnU561QtklI6d+VuW/0vwoYiltk a0001 connect bot"
  ];
  services.openssh.extraConfig = ''
    Ciphers chacha20-poly1305@openssh.com,aes256-cbc,aes256-gcm@openssh.com,aes256-ctr
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    MACs umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
  '';

  documentation.nixos.enable = false;
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  #services.openssh.hostKeys = [
  #  { type = "rsa"; bits = 4096; path = "/etc/ssh/ssh_host_rsa_key"; }
  #  { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }
  #];
}
