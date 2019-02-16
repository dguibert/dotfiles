{ versions ? import ./versions.nix
, nixpkgs ? versions.nixpkgs
# , nur_dguibert ? versions.nur_dguibert
, home-manager ? versions.home-manager
#, nixpkgs ? builtins.getEnv "HOME" + "/code/nixpkgs"
, nur_dguibert ? builtins.getEnv "HOME" + "/nur-packages" # versions.nur_dguibert
#, home-manager ? builtins.getEnv "HOME" + "/code/home-manager" # versions.home-manager
#, nixops ? versions.nixops
, nixops ? builtins.getEnv "HOME" + "/code/nixops"
, overlays_ ? []

, pkgs ? import nixpkgs {
    config = (import "${nur_dguibert}/config.nix");
    overlays = [
      (import "${nur_dguibert}/overlays").default
    ] ++ overlays_;
  }
}:
let

in with pkgs; lib.mkEnv {
  name = "nixops";
  buildInputs = [
    (import "${nixops}/release.nix" { }).build.x86_64-linux
  ];
  shellHook = ''
    unset NIX_INDENT_MAKE
    unset IN_NIX_SHELL
    unset TMP
    unset TMPDIR

    export NIX_PATH=nixpkgs=${nixpkgs}:nur_dguibert=${nur_dguibert}:home-manager=${home-manager}:.:$NIX_PATH
  '';
}
