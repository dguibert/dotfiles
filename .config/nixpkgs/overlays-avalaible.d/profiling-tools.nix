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
	  name = "score-p-3.0";
	  src = self.fetchurl {
	  	url = "http://www.vi-hps.org/upload/packages/scorep/scorep-3.0.tar.gz";
		sha256 = "1gn05pn9zkpc3b8g72w1axjw7s8dx7vibsr8fszvpcrrh85gxry9";
	  };
	  buildInputs = [ self.otf2 self.openmpi self.which self.gfortran self.zlib /*opari*/ ];
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
