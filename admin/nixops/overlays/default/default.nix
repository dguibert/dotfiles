final: prev: with final; let
  inputs = prev.inputs;
in
{
  swayidle = prev.swayidle.overrideAttrs (o: {
    postPatch = (o.postPatch or "") + ''
      sed -i -e 's@"sh"@"${bash}/bin/bash"@' main.c
    '';
  });
  # Patch libvirt to use ebtables-legacy
  libvirt =
    if prev.libvirt.version <= "5.4.0" && prev.ebtables.version > "2.0.10-4"
    then
      prev.libvirt.overrideAttrs
        (oldAttrs: rec {
          EBTABLES_PATH = "${final.ebtables}/bin/ebtables-legacy";
        })
    else prev.libvirt;

  install-script = drv: with final; writeScript "install-${drv.name}"
    ''#!/usr/bin/env bash
      set -x

      nixos-install --system ${drv} $@

      umount -R /mnt
      zfs set mountpoint=legacy bt580/nixos
      zfs set mountpoint=legacy rt580/tmp
    '';

  dwm = prev.dwm.overrideAttrs (o: {
    src = inputs.dwm-src;
    patches = [ ];
  });
  st = prev.st.overrideAttrs (o: {
    src = inputs.st-src;
    patches = [ ];
  });
  dwl = prev.dwl.overrideAttrs (o: {
    version = "0.3.1-custom";
    src = inputs.dwl-src;
    buildInputs = o.buildInputs ++ [
      xorg.xcbutilwm
    ];
  });
  yambar = prev.yambar.overrideAttrs (o: {
    src = inputs.yambar-src;
    patches = [ ];
  });
  somebar = prev.somebar.overrideAttrs (o: {
    src = inputs.somebar-src;
    patches = [
      ./patches/0001-Replaces-somebar-s-channel-to-dwl-from-stdin-to-a-wa.patch
      ./patches/0002-bigger-occupied-rectangle.patch
      ./patches/0003-add-net-tapesoftware-dwl-wm-unstable-v1-protocols.patch
    ];
  });

}

