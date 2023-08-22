final: prev: with final; {
  install-script = drv: with final; writeScript "install-${drv.name}"
    ''#!/usr/bin/env bash
      set -x

      nixos-install --system ${drv} $@

      umount -R /mnt
      zfs set mountpoint=legacy bt580/nixos
      zfs set mountpoint=legacy rt580/tmp
    '';

  conky_nox11 = (conky.override { x11Support = false; });

  #nixos-option = prev.nixos-option.override {
  #  nix = prev.nixStable;
  #};
}

