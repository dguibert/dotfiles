# vim: set ts=2 :
{ pkgs }:
with pkgs.lib;
{
  permittedInsecurePackages = [
    "oraclejdk-10.0.2"
  ];
  psxe.licenseFile = ~/admin/nixops/secrets/pxse2019.1019.lic;

  dwm.patches = [
    ./dwm.patches/0001-pertag.patch
    ./dwm.patches/0002-apply-dwm-6.1-systray.diff.patch
    ./dwm.patches/0003-config.h-azerty.patch
    ./dwm.patches/0004-config.h-audio-controls.patch
    ./dwm.patches/0005-solarized-theme.patch
    ./dwm.patches/0006-config-support-shortcuts-for-vbox-inside-windows.patch
    ./dwm.patches/0007-light-solarized-theme.patch
    ./dwm.patches/0008-xpra-as-float.patch
    ./dwm.patches/0009-qtpass-as-float.patch
    ./dwm.patches/0010-pinenetry-as-float.patch
  ];
  st.patches = [
    ./st.patches/0001-apply-st-no_bold_colors-20170623-b331da5.diff.patch
    ./st.patches/0002-apply-st-solarized-light-20170623-b331da5.diff.patch
    ./st.patches/0003-custom-changes.patch
    ./st.patches/0004-apply-st-scrollback-0.8.diff.patch
  ];
  allowUnfree = true;
  pulseaudio = true;
  virtualbox.enableExtensionPack = true;

  packageOverrides = super: let self = super.pkgs; in with self; {
	  home-manager = import ./home-manager { inherit pkgs; };

    git-credential-password-store = stdenv.mkDerivation {
      name = "git-credential-password-store";
      src = fetchFromGitHub {
        owner = "ccrusius";
	repo = "git-credential-password-store";
	rev = "225582e9a1a9bd9a63e3dfde858f4cc028b07d3e";
	sha256 = "06ly4qcy0g57jyqnl5q524pcypm85ny4pzac3ljz1dim181zlq3c";
      };
      preBuild = "ln -s GNUmakefile Makefile";
      installFlags = "PREFIX=$(out)";
      buildInputs = [ gnugrep ];
    };
	  #pkgsWithGcc6 = let
    	  #  gccOverrides = self: super: {
    	  #    stdenvGcc6 = self.overrideCC self.stdenv self.gcc6;
    	  #    gcc = self.gcc6;
    	  #    gfortran = self.gfortran6;

    	  #    hdf5 = super.hdf5.override { stdenv = self.stdenvGcc6; };
    	  #    openmpi = super.openmpi.override { stdenv = self.stdenvGcc6; };
    	  #  };
    	  #in fix' (extends gccOverrides self.__unfix__);

  };
}
