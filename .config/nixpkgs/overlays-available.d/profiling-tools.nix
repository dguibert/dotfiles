self: super:
{
  otf2 = self.stdenv.mkDerivation {
	  name = "otf2-2.0";
	  src = self.fetchurl {
		  url = "http://www.vi-hps.org/upload/packages/otf2/otf2-2.0.tar.gz";
		  sha256 = "0m178qlnx7rf7nsywk4v2l3xj1fk7g44sxz5d0ayf4qaiv00mzms";
	  };
  };
  score-p = self.stdenv.mkDerivation {
	  name = "score-p-3.1";
	  src = self.fetchurl {
	  	url = "http://www.vi-hps.org/upload/packages/scorep/scorep-3.1.tar.gz";
		sha256 = "0h45357djna4dn9jyxx0n36fhhms3jrf22988m9agz1aw2jfivs9";
	  };
	  buildInputs = [ self.otf2 self.openmpi self.which self.gfortran self.zlib /*opari*/ ];
	  postInstall = ''
	  # RPATH of binary /nix/store/8b7q0yzfb8chmgr4yqybfrlrvvnrlq1i-score-p-3.0/bin/scorep-score contains a forbidden reference to /tmp/nix-build-score-p-3.1.drv-0
	  while IFS= read -r -d ''$'\0' i; do
            if ! isELF "$i"; then continue; fi
            echo "patching $i..."
            rpath=`patchelf --print-rpath $i | sed -e "s@$TMPDIR/.*:@\$out/lib:@"`;
            patchelf --set-rpath "$rpath" "$i"
          done < <(find $out/bin -type f -print0)
	  '';
  };
  muster = self.stdenv.mkDerivation {
	  name = "muster";
	  src = self.fetchFromGitHub {
		owner = "LLNL";
		repo = "muster";
		rev = "b58796b62689e178008ae484829bef03e7908766";
		sha256 = "0w5054qwk970b9i37njwfsa7z7mgb9w6agyl1arx0f69wblc24is";
	  };
	  buildInputs = [ self.cmake self.boost self.openmpi ];
  };
  ravel = self.stdenv.mkDerivation {
	  name = "ravel";
	  src = self.fetchFromGitHub {
		owner = "LLNL";
		repo = "ravel";
	       	rev = "67f0e95178074998e9eee53a53c9ae9084af6b2e";
		sha256 = "00f7k8w9akjjb6sz20ajgc7blcan2kamdliaac56p36yx6krxl0i";
	  };
	  buildInputs = [ self.otf2 self.muster self.openmpi self.cmake self.qt5.qtbase self.boost ];
  };
}
