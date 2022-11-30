{ config, pkgs, lib, ... }:
{
  boot.consoleLogLevel = 6; #KERN_INFO
  environment.systemPackages = [ pkgs.vim pkgs.git ];
  # Select internationalisation properties.
  console.font = "Lat2-Terminus16";
  console.keyMap = lib.mkDefault "fr";
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Enable ZeroTierOne
  services.zerotierone.enable = false;
  services.zerotierone.joinNetworks = [ "e5cd7a9e1cd44c48" ];

  networking.useNetworkd = true;
  systemd.network.enable = true;
  services.resolved.extraConfig = "DNS=8.8.8.8 8.8.4.4";
  services.resolved.dnssec = "false";
  # https://github.com/NixOS/nixpkgs/issues/18962
  # Prevent networkd from managing unconfigured links.
  #systemd.network.networks."99-main".enable = false;
  # https://github.com/systemd/systemd/issues/9771
  # https://discourse.nixos.org/t/domain-name-resolve-problem/885
  networking.resolvconf.dnsExtensionMechanism = false; #disable the edns0 option in resolv.conf. (most popular user of that feature is DNSSEC)
  #services.nscd.enable = false; # no real gain (?) on workstations
  # unreachable DNS entries from home
  networking.hosts = {
    "209.51.188.200" = [ "ftpmirror.gnu.org" ];
    "209.51.188.201" = [ "git.savannah.gnu.org" ];
  };

  services.openssh.startWhenNeeded = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.extraConfig = ''
    AcceptEnv COLORTERM
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
