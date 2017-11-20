self: super:
{
  otf2 = super.stdenv.mkDerivation {
	  name = "otf2-2.0";
	  src = super.fetchurl {
		  url = "http://www.vi-hps.org/upload/packages/otf2/otf2-2.0.tar.gz";
		  sha256 = "0m178qlnx7rf7nsywk4v2l3xj1fk7g44sxz5d0ayf4qaiv00mzms";
	  };
  };
  score-p = super.stdenv.mkDerivation {
	  name = "score-p-3.1";
	  src = super.fetchurl {
	  	url = "http://www.vi-hps.org/upload/packages/scorep/scorep-3.1.tar.gz";
		sha256 = "0h45357djna4dn9jyxx0n36fhhms3jrf22988m9agz1aw2jfivs9";
	  };
	  buildInputs = [ self.otf2 super.openmpi super.which super.gfortran super.zlib /*opari*/ ];
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
  muster = super.stdenv.mkDerivation {
	  name = "muster";
	  src = super.fetchFromGitHub {
		owner = "LLNL";
		repo = "muster";
		rev = "b58796b62689e178008ae484829bef03e7908766";
		sha256 = "0w5054qwk970b9i37njwfsa7z7mgb9w6agyl1arx0f69wblc24is";
	  };
	  buildInputs = [ super.cmake super.boost super.openmpi ];
  };
  ravel = super.stdenv.mkDerivation {
	  name = "ravel";
	  src = super.fetchFromGitHub {
		owner = "LLNL";
		repo = "ravel";
	       	rev = "67f0e95178074998e9eee53a53c9ae9084af6b2e";
		sha256 = "00f7k8w9akjjb6sz20ajgc7blcan2kamdliaac56p36yx6krxl0i";
	  };
	  buildInputs = [ self.otf2 self.muster super.openmpi super.cmake super.qt5.qtbase super.boost ];
  };
  dyninst = super.stdenv.mkDerivation {
	  name = "dyninst-9.2.0";
	  src = super.fetchFromGitHub {
		owner = "dyninst";
		repo = "dyninst";
	       	rev = "refs/tags/v9.2.0";
		sha256 = "140hpxs5v60cvf92hxa98vyk9fcnn7h2xarhxzwki5yx8d7vgma2";
	  };
	  buildInputs = [ super.cmake super.boost super.libelf super.libdwarf super.libiberty ];
	  postPatch = "patchShebangs .";
	  cmakeFlags = [
		  "-DBUILD_RTLIB_32=ON"
	  ];
  };
  Mitos = super.stdenv.mkDerivation {
	  name = "Mitos-20160228";
	  #name = "Mitos-20171119";
	  src = super.fetchFromGitHub {
		owner = "LLNL";
		repo = "Mitos";
	       	rev = "434597dc78f3cb52be2582938b0115c8332f1c40";
		sha256 = "1plyan27szy74av49vbd1cipkyjs4z367pb7f3jwr6fkpvnlj419";
		#rev = "0466847d9fcffb5bb19e0479c6d85788f0c07883"; # develop 20171119
		#sha256 = "1mnmxh7jaa95yx2k31b8yvhaivgmz0jsf99dz0sxyknzsn93fx6w";
	  };
	  buildInputs = [ super.cmake super.boost self.dyninst super.hwloc super.openmpi ];
  };
  MemAxes = super.stdenv.mkDerivation {
	  name = "MemAxes-20150408";
	  src = super.fetchFromGitHub {
		owner = "LLNL";
		repo = "MemAxes";
	       	rev = "57fb31635927960195169b6d6f1ba8f8f70adb1b";
		sha256 = "17xc3a6h7dqa3srbc8q1ljphqxmg41qkhyaha68qv85vk7y4pzaq";
	  };
	  patches = [ ../memaxes-pcvizwidget.patch ];
	  buildInputs = [ super.cmake super.qt5.qtbase ];
  };
 
}
