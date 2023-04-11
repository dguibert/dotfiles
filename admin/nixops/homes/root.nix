{ config, lib, inputs, withSystem, self, ... }:
let
  genHomeManagerConfiguration = import ../lib/gen-home-manager-configuration.nix { inherit lib; };
in
{
  imports = [
    (genHomeManagerConfiguration "aarch64-linux" "root@rpi31")
    (genHomeManagerConfiguration "aarch64-linux" "root@rpi41")
    (genHomeManagerConfiguration "x86_64-linux" "root@t580")
    (genHomeManagerConfiguration "x86_64-linux" "root@titan")
  ];

  modules.homes."root@rpi31" = [ ({ ... }: { imports = [ ../modules/home-manager/root.nix ]; }) ];
  modules.homes."root@rpi41" = [ ({ ... }: { imports = [ ../modules/home-manager/root.nix ]; }) ];
  modules.homes."root@t580" = [ ({ ... }: { imports = [ ../modules/home-manager/root.nix ]; }) ];
  modules.homes."root@titan" = [ ({ ... }: { imports = [ ../modules/home-manager/root.nix ]; }) ];
}
