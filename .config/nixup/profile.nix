# NixUP configuration root file

{config, lib, pkgs, ...}:

with lib;

{
  config = {

    imperativeNix.enable = true;

    user.packages = with pkgs; [ vim gitAndTools.git-annex ];

  };

}
