let
  # https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/
  fetcher = {type ? "github", ...}@args: fetchers."${type}" args;

  fetchers = {
    github = { owner?null, repo?null, rev?null, branch?null
      , url ? "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz"
      , sha256
      , type ? "github"
    }: if owner == null then
      builtins.fetchGit {
        inherit url rev;
      }
    else
      builtins.fetchTarball {
        inherit url sha256;
      };
    url = {url, sha256, type}: builtins.fetchTarball { inherit url sha256; };
  };

  versions = builtins.mapAttrs
     (_: fetchOrPath) sources;

  sources = (builtins.fromJSON (builtins.readFile ./versions.json));

  NIX_PATH = builtins.concatStringsSep ":" (builtins.map (x: "${x}=${versions."${x}"}") (builtins.attrNames versions))
           + ":.";

  fetchOrPath = value:
    if builtins.typeOf value == "set" then
      fetcher value
    else
      toString value;

  inherit (import versions.nixpkgs {}) writeScript;

  version-updater = writeScript "version-updater.sh" ''
    #! /usr/bin/env nix-shell
    #! nix-shell -i bash
    #! nix-shell -p curl jq nix git nix-prefetch-scripts
    ## vim: ft=sh :
    ### https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/
    ### https://nmattia.com/posts/2019-01-15-easy-peasy-nix-versions.html

    test -n "$VERBOSE" && set -x
    set -eufo pipefail
    unset GIT_DIR GIT_WORKTREE

    FILE=$1
    PROJECT=$2

    OWNER=$(cat $FILE | jq -r ".[\"$PROJECT\"].owner")
    REPO=$(cat $FILE | jq -r ".[\"$PROJECT\"].repo")
    BRANCH=$(cat $FILE | jq -r ".[\"$PROJECT\"].branch")
    REV="null"

    if [ "''${OWNER}" != "null" ]; then
      REV=$(curl "https://api.github.com/repos/$OWNER/$REPO/branches/$BRANCH" | jq -r '.commit.sha')
      URL="https://github.com/$OWNER/$REPO/archive/$REV.tar.gz"
      SHA256=$(nix-prefetch-url --unpack "$URL")
    elif [ "''${BRANCH}" != "null" ]; then
      URL=$(jq -r '.[$project].url' --arg project "$PROJECT" < "$FILE")
      REV=$(git ls-remote $URL | grep refs/heads/$BRANCH | awk '{print $1}')
      SHA256=$(nix-prefetch-git "$URL" "$REV" | jq -r '.sha256')
    else
      URL=$(jq -r '.[$project].url' --arg project "$PROJECT" < "$FILE")
      NAME=$(jq -r '.[$project].name' --arg project "$PROJECT" < "$FILE")
      SHA256=$(nix-prefetch-url --unpack "$URL")
    fi

    if [ "''${REV}" != "null" ]; then
    TJQ=$(cat $FILE \
        | jq -rM ".[\"$PROJECT\"].rev = \"$REV\"" \
        | jq -rM ".[\"$PROJECT\"].sha256 = \"$SHA256\""
        )
    else
    TJQ=$(cat $FILE \
        | jq -rM ".[\"$PROJECT\"].sha256 = \"$SHA256\""
        )
    fi

    if [[ $? == 0 ]]; then
      diff -u <(cat $FILE | jq -S .) <(echo "$TJQ" | jq -S .) || true
      echo "''${TJQ}" >| "$FILE"
    fi
  '';

  updater = writeScript "updater.sh" ''
    #!/usr/bin/env bash
    ${version-updater} versions.json nixpkgs
    ${version-updater} versions.json krops
    ${version-updater} versions.json nur_dguibert
    ${version-updater} versions.json nixos-17.09
    ${version-updater} versions.json nixos-18.03
    ${version-updater} versions.json nixos-18.09
    ${version-updater} versions.json nixos-19.03
    ${version-updater} versions.json home-manager
    ${version-updater} versions.json base16-nix
    ${version-updater} versions.json NUR
    ${version-updater} versions.json gitignore
  '';
in versions // { inherit updater NIX_PATH sources; }
