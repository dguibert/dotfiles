{ inputs, pkgs, ... }:
inputs.flake-utils.lib.mkApp {
  drv = pkgs.writeScriptBin "nix-spartan" (with pkgs; let
    name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
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
        '';
      in
      "${nixConf}/opt";

  in
  ''
    #!${runtimeShell}
    export XDG_CACHE_HOME=$HOME/.cache/${name}
    export PATH=${pkgs.nix}/bin:$PATH
    export NIX_CONF_DIR=${NIX_CONF_DIR}
    export NIX_STORE=${nixStore}/store
    $@
  '');
}
