{ pkgs ? import <nixpkgs> { }
, flakes ? {}
, sops
, sops-pgp-hook
}:
with pkgs;

mkEnv rec {
  name = "deploy";

  # imports all files ending in .asc/.gpg and sets $SOPS_PGP_FP.
  sopsPGPKeyDirs = [
  #  #"./keys/hosts"
  #  #"./keys/users"
  ];
  # Also single files can be imported.
  sopsPGPKeys = [
    "./keys/hosts/titan.asc"
    "./keys/users/dguibert.asc"
  #  "./keys/users/mic92.asc"
  #  "./keys/hosts/server01.asc"
  ];
  buildInputs = [
    nix
    nixops
    sops-pgp-hook
    #nix-diff # Package ‘nix-diff-1.0.8’ in /nix/store/1bzvzc4q4dr11h1zxrspmkw54s7jpip8-source/pkgs/development/haskell-modules/hackage-packages.nix:174705 is marked as broken, refusing to evaluate.

    jq
  ];
  SOPS_PGP_FP = "";
  shellHook = ''
    unset NIX_INDENT_MAKE
    unset IN_NIX_SHELL NIX_REMOTE
    unset TMP TMPDIR

    # https://blog.wearewizards.io/how-to-use-nixops-in-a-team
    export NIXOPS_STATE=secrets/deploy.nixops

    export DISNIXOS_USE_NIXOPS=1
    export DISNIX_TARGET_PROPERTY=target

    export PASSWORD_STORE_DIR=$PWD/secrets
    export SHELL=${bashInteractive}/bin/bash

    export XDG_CACHE_HOME=$HOME/.cache/${name}
    unset NIX_STORE NIX_DAEMON
    NIX_PATH=
    ${lib.concatMapStrings (f: ''
      NIX_PATH+=:${toString f}=${toString flakes.${f}}
    '') (builtins.attrNames flakes) }
    export NIX_PATH

    NIX_OPTIONS=()
    NIX_OPTIONS+=("--option plugin-files ${(nix-plugins.override { nix = nix; }).overrideAttrs (o: {
        buildInputs = o.buildInputs ++ [ boehmgc nlohmann_json ];
        patches = (o.patches or []) ++ [
          ./nix-plugins-PrimOp.patch
        ];
      })}/lib/nix/plugins/libnix-extra-builtins.so")
    NIX_OPTIONS+=("--option extra-builtins-file ${extra_builtins_file pkgs}")
    export NIX_OPTIONS

    export EXTRA_NIX_OPTS="''${NIX_OPTIONS[@]}"
    sopsPGPHook
  '';
}
