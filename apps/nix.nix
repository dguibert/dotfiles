{ config, inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      drv = pkgs.writeScriptBin "nix" (with pkgs; let
        name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] (builtins.dirOf builtins.storeDir)}";
        NIX_CONF_DIR =
          let
            nixConf = pkgs.writeTextDir "opt/nix.conf" ''
              sandbox = false
              auto-optimise-store = true
              allowed-users = *
              system-features = recursive-nix nixos-test benchmark big-parallel kvm
              sandbox-fallback = false
              keep-outputs = true       # Nice for developers
              keep-derivations = true   # Idem
              experimental-features = nix-command flakes recursive-nix ca-derivations
              system-features = recursive-nix nixos-test benchmark big-parallel gccarch-x86-64 kvm
              extra-platforms = i686-linux aarch64-linux
              store = local?store=${builtins.storeDir}&state=${builtins.dirOf builtins.storeDir}/state&log=${builtins.dirOf builtins.storeDir}/log'
            '';
          in
          "${nixConf}/opt";

      in
      ''
        #!${runtimeShell}
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        export NIX_CONF_DIR=${NIX_CONF_DIR}
        $@
      '');
    in
    {
      checks.app-nix = drv;
      apps.nix = inputs.flake-utils.lib.mkApp {
        inherit drv;
      };
    };
}
