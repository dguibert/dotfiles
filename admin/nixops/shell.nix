{ versions ? import ./versions.nix
, nixpkgs ? { outPath = versions.nixpkgs; revCount = 123456; shortRev = "gfedcba"; }
, nur_dguibert ? { outPath = versions.nur_dguibert; revCount = 123456; shortRev = "gfedcba"; }
, overlays_ ? []
#, overlays_ ? [ (import "${nur_dguibert}/overlays/local-aloy.nix") ]
, system ? builtins.currentSystem

, pkgs ? import nixpkgs {
    config = import "${nur_dguibert}/config.nix";
    overlays = let
      overlays' = import "${nur_dguibert}/overlays";
    in [
      overlays'.default
    ] ++ overlays_;
  }
}:

let
  nix = pkgs.nix;

in with pkgs; mkShell {
  buildInputs = [
    #nix
    #(import "${nixops}/release.nix" { }).build.x86_64-linux
    #nixops
  ];
  inherit (versions) NIX_PATH;
  shellHook = ''
    unset NIX_INDENT_MAKE
    unset IN_NIX_SHELL
    unset TMP TMPDIR

    # https://blog.wearewizards.io/how-to-use-nixops-in-a-team
    export HOME=/home/dguibert
    export GIT_DIR=$HOME/.mgit/dotfiles/.git
    export NIXOPS_STATE=secrets/deploy.nixops

    export DISNIXOS_USE_NIXOPS=1
    export DISNIX_TARGET_PROPERTY=target

    export PASSWORD_STORE_DIR=$PWD/secrets
    export SHELL=${bashInteractive}/bin/bash
'';
}
