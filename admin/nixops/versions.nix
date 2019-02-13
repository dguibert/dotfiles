let
  # https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/
  fetcher = { owner?null, repo?null, rev, sha256, branch
    , url ? "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz"
  }: if owner == null then
    builtins.fetchGit {
      inherit url rev;
    }
  else
    builtins.fetchTarball {
      inherit url sha256;
    };
  versions = builtins.mapAttrs
     (_: fetcher)
       (builtins.fromJSON (builtins.readFile ./versions.json));

  inherit (import versions.nixpkgs {}) writeScript;
  updater = writeScript "updater.sh" ''
    #!/usr/bin/env bash
    ${./version-updater.sh} versions.json nixpkgs
    ${./version-updater.sh} versions.json nur_dguibert
    ${./version-updater.sh} versions.json nixos-17.09
    ${./version-updater.sh} versions.json nixos-18.03
    ${./version-updater.sh} versions.json nixos-18.09
    ${./version-updater.sh} versions.json home-manager
  '';
in versions // updater
