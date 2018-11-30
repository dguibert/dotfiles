self: super:
{
  nix = super.nix.override {
    storeDir = "/scratch_lustre_na/bguibertd/nix/store";
    stateDir = "/scratch_lustre_na/bguibertd/nix/var";
  };
  coreutils = self.lib.overrideDerivation super.coreutils (attrs: {
    doCheck = false;
  });
  findutils = self.lib.overrideDerivation super.findutils (attrs: {
    preConfigure = ''
    # First, suppress a test which on some machines can loop forever:
      sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
    '';
  });
}

