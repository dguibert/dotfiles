# https://tech.ingolf-wagner.de/nixos/krops/
let
  versions = import ./versions.nix;

  NIX_PATH = versions.NIX_PATH;

  lib = import "${versions.krops}/lib";
  pkgs = import "${versions.krops}/pkgs" { };

  inherit (import versions.gitignore { inherit (pkgs) lib; }) gitignoreSource;

  source = name: lib.evalSource [{
    nixpkgs.file = versions.nixpkgs;
    home-manager.file = versions.home-manager;
    nur_dguibert.file = (gitignoreSource versions.nur_dguibert).outPath;
    base16-nix.file = versions.base16-nix;
    NUR.file = versions.NUR;

    config.file = toString ./config;
    modules.file = toString ./modules;
    nixos-config.symlink = "config/${name}/configuration.nix";
    secrets.pass = {
      dir  = toString ./secrets;
      name = "${name}";
    };
  }];

  rpi31 = pkgs.krops.writeScript "deploy-rpi31" ''
      set -efu
      ${lib.populate { force=false;
                   source=source "rpi31";
                   target = lib.mkTarget "rpi31"; }} >&2
  '';

  writeDeploy' = name: { force ? false, source, target-host, build-host }: let
    target' = lib.mkTarget target-host;
    build-host' = lib.mkTarget build-host;
  in
    pkgs.writeDash name ''
      set -efux
      ${pkgs.populate { inherit force source; target = build-host'; }}
      ${pkgs.populate { inherit force source; target = target'; }}
      ${nixos-rebuild ["switch"] build-host' target'}
    '';
  nixos-rebuild = args: build-host: target:
    pkgs.exec "nixops-rebuild.${build-host.host}.${target.host}" rec {
      filename = "/run/current-system/sw/bin/nixos-rebuild";
      argv = [
        filename
      ] ++ [
        "--build-host" build-host.host
        "--target-host" "${target.user}@${target.host}"
        "-I" build-host.path
      ] ++ args;
    };



/* --build-host
Instead of building the new configuration locally, use the specified host to perform the build. The host needs to be accessible with ssh, and must be able to perform Nix builds. If the option --target-host is not set, the
build will be copied back to the local machine when done.

Note that, if --no-build-nix is not specified, Nix will be built both locally and remotely. This is because the configuration will always be evaluated locally even though the building might be performed remotely.

You can include a remote user name in the host name (user@host). You can also set ssh options by defining the NIX_SSHOPTS environment variable.

--target-host
Specifies the NixOS target host. By setting this to something other than localhost, the system activation will happen on the remote host instead of the local machine. The remote host needs to be accessible over ssh, and
for the commands switch, boot and test you need root access.

If --build-host is not explicitly specified, --build-host will implicitly be set to the same value as --target-host. So, if you only specify --target-host both building and activation will take place remotely (and no build
artifacts will be copied to the local machine).

You can include a remote user name in the host name (user@host). You can also set ssh options by defining the NIX_SSHOPTS environment variable.
*/
  orsine = writeDeploy' "deploy-orsine" {
    source = source "orsine";
    target-host = "root@orsine/var/src/orsine";
    build-host = "dguibert@titan:22/var/src/orsine";
  };

in {
  inherit rpi31 orsine ;
  all = pkgs.krops.writeScript "deploy-home-servers"
    (pkgs.lib.concatStringSep "\n" [ rpi31 orsine ]);
}
