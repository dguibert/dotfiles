{ pkgs ? import <nixpkgs> { }
, inputs ? {}
, ssh-to-pgp
, sops-import-keys-hook
, deploy-rs
}:
with pkgs;

mkShell rec {
  name = "deploy";
  ENVRC = name;

  # imports all files ending in .asc/.gpg and sets $SOPS_PGP_FP.
  #sopsPGPKeyDirs = [
  ##  #"./keys/hosts"
  ##  #"./keys/users"
  #];
  # Also single files can be imported.
  sopsPGPKeys = [
    "./keys/hosts/titan.asc"
    "./keys/hosts/rpi41.asc"
    "./keys/hosts/rpi31.asc"
    "./keys/hosts/t580.asc"
    "./keys/users/dguibert.asc"
  ];
  buildInputs = [
    ssh-to-pgp
    deploy-rs
    #nix-diff # Package ‘nix-diff-1.0.8’ in /nix/store/1bzvzc4q4dr11h1zxrspmkw54s7jpip8-source/pkgs/development/haskell-modules/hackage-packages.nix:174705 is marked as broken, refusing to evaluate.

    jq
  ];
  nativeBuildInputs = [
    sops-import-keys-hook
  ];
  #SOPS_PGP_FP = "";
  sopsCreateGPGHome="";
  shellHook = ''
    unset NIX_INDENT_MAKE
    unset IN_NIX_SHELL NIX_REMOTE
    unset TMP TMPDIR

    export XDG_CACHE_HOME=$HOME/.cache/${name}
    unset NIX_STORE NIX_DAEMON
    NIX_PATH=
    ${lib.concatMapStrings (f: ''
      NIX_PATH+=:${toString f}=${toString inputs.${f}}
    '') (builtins.attrNames inputs) }
    export NIX_PATH

    NIX_OPTIONS=()
    NIX_OPTIONS+=("--option extra-builtins-file ${extra_builtins_file}")
    export NIX_OPTIONS

    export EXTRA_NIX_OPTS="''${NIX_OPTIONS[@]}"

    export PASSWORD_STORE_DIR=$PWD/secrets
  '';
}
