{ config, lib, pkgs, utils, ... }:
{
  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoSnapshot.flags = "-k -p --utc";
}

