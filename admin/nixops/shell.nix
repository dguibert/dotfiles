{ versions ? import ./versions.nix
, nixpkgs ? versions.nixpkgs
, home-manager ? versions.home-manager
, nur_dguibert ? builtins.getEnv "HOME" + "/nur-packages" # versions.nur_dguibert
, nixops ? builtins.getEnv "HOME" + "/code/nixops"
, base16-nix ? versions.base16-nix
, overlays_ ? []

, pkgs ? import nixpkgs {
    config = (import "${nur_dguibert}/config.nix");
    overlays = [
      (import "${nur_dguibert}/overlays").default
    ] ++ overlays_;
  }
}:
let
  nix = pkgs.nix;

in with pkgs; mkEnv {
  name = "nixops";
  buildInputs = [
    nix
    #(import "${nixops}/release.nix" { }).build.x86_64-linux
    nixops
  ];
  inherit nix;
  shellHook = ''
    unset NIX_INDENT_MAKE
    unset IN_NIX_SHELL
    unset TMP
    unset TMPDIR
  '';
}
