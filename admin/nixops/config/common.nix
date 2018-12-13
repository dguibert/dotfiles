{ config, pkgs, lib, ... }:
{
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
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ "e5cd7a9e1cd44c48" ];

  networking.useNetworkd = true;
  systemd.network.enable = true;
  networking.dnsExtensionMechanism=false; #disable the edns0 option in resolv.conf. (most popular user of that feature is DNSSEC)
  services.nscd.enable = false; # no real gain (?) on workstations
  # unreachable DNS entries from home
  networking.hosts = {
    "208.118.235.200" = [ "ftpmirror.gnu.org" ];
    "208.118.235.201" = [ "git.savannah.gnu.org" ];
  };

  # disnix target
  dysnomia.properties.mem = "$(grep 'MemTotal:' /proc/meminfo | sed -e 's/kB//' -e 's/MemTotal://' -e 's/ //g')";
  dysnomia.properties.disks = "$(ls /dev/disk/by-id/ | grep -v -- '-part.*' | tr '\\\\n' ' ')";
  # https://hydra.nixos.org/job/disnix/disnix-trunk/tarball/latest/download-by-type/doc/manual/#chap-packages
  environment.variables.PATH = [ "/nix/var/nix/profiles/disnix/default/bin" ];

  # Package ‘openafs-1.6.22.2-4.18.4’ in /home/dguibert/code/nixpkgs/pkgs/servers/openafs/1.6/module.nix:49 is marked as broken, refusing to evaluate.
  nixpkgs.config.allowBroken = true;
}
