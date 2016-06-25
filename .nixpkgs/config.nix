{ pkgs }:
with pkgs.lib;
{
  dwm.patches = [
    ./dwm.patches/0001-pertag.patch
    ./dwm.patches/0002-apply-dwm-6.1-systray.diff.patch
    ./dwm.patches/0003-config.h-azerty.patch
    ./dwm.patches/0004-config.h-audio-controls.patch
    ./dwm.patches/0005-solarized-theme.patch
    ./dwm.patches/0006-config-support-shortcuts-for-vbox-inside-windows.patch
    ./dwm.patches/0007-light-solarized-theme.patch
  ];
  st.patches = [
    ./st.patches/0001-patch-apply-st-scrollback-git-20160620-528241a.diff.patch
    ./st.patches/0002-patch-apply-st-no_bold_colors-git-20160620-528241a.d.patch
    ./st.patches/0003-patch-apply-st-solarized-light-git-20160620-528241a..patch
    ./st.patches/0004-custom-changes.patch
  ];
  allowUnfree = true;
  pulseaudio = true;
  chromium.enablePepperFlash = true;
  virtualbox.enableExtensionPack = true;

  packageOverrides = super: let self = super.pkgs; in {
    pkgsWithGcc6 = let
      gccOverrides = self: super: {
        stdenvGcc6 = self.overrideCC self.stdenv self.gcc6;
        gcc = self.gcc6;
        gfortran = self.gfortran6;

        hdf5 = super.hdf5.override { stdenv = self.stdenvGcc6; };
        openmpi = super.openmpi.override { stdenv = self.stdenvGcc6; };
      };
    in fix' (extends gccOverrides self.__unfix__);

  };
}
