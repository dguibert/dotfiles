{ system ? builtins.currentSystem
}:
let

  versions = import ./lib/versions.nix;
  pkgs_haskell_updates = import versions.haskell-updates { inherit system; };
  #pkgs_master = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz)       { inherit system; };
  #pkgs_nix_2_0 = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/nix-2.0.tar.gz)     { inherit system; };
  #pkgs_17_09 = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/release-17.09.tar.gz) { inherit system; };
in self: super: {
  #nix = pkgs_nix_2_0.nix;
  #pandoc = pkgsMaster.pandoc;

  gitAndTools = (super.gitAndTools or {}) // {
  ##  # # The Hackage tarball is purposefully broken, because it's not intended to be, like, useful.
  ##  ## https://git-annex.branchable.com/bugs/bash_completion_file_is_missing_in_the_6.20160527_tarball_on_hackage/
  ##  git-annex = super.haskell.lib.dontCheck pkgs_haskell_updates.gitAndTools.git-annex;
    git-annex = super.haskell.lib.dontCheck (super.haskell.lib.overrideSrc pkgs_haskell_updates.gitAndTools.git-annex {
      src = super.fetchgit {
        name = "git-annex-${pkgs_haskell_updates.gitAndTools.git-annex.version}-src";
        url = "git://git-annex.branchable.com/";
        rev = "refs/tags/" + pkgs_haskell_updates.gitAndTools.git-annex.version;
        #upstream via 1bc120fa5faf996a248bdbb4cb7c4327ca368e06
        sha256 = "0mgmxcr36b86jh56my3vhp9y4cravi0hbppa463q3c21a1cmjc19";
      };
    });
  };
}
