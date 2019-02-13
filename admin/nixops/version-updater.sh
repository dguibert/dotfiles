#! /usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p curl jq nix git nix-prefetch-scripts
## vim: ft=sh :
### https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/
### https://nmattia.com/posts/2019-01-15-easy-peasy-nix-versions.html

test -n "$VERBOSE" && set -x
set -eufo pipefail

FILE=$1
PROJECT=$2

OWNER=$(cat $FILE | jq -r ".[\"$PROJECT\"].owner")
REPO=$(cat $FILE | jq -r ".[\"$PROJECT\"].repo")
BRANCH=$(cat $FILE | jq -r ".[\"$PROJECT\"].branch")

if [ "${OWNER}" != "null" ]; then
  REV=$(curl "https://api.github.com/repos/$OWNER/$REPO/branches/$BRANCH" | jq -r '.commit.sha')
## Ask GitHub what the latest commit (revision) is on $branch:
#new_rev=$(curl -sfL \
#            https://api.github.com/repos/$owner/$repo/git/refs/heads/$branch \
#            | jq -r .object.sha)
  URL="https://github.com/$OWNER/$REPO/archive/$REV.tar.gz"
  SHA256=$(nix-prefetch-url --unpack "$URL")
else
  URL=$(jq -r '.[$project].url' --arg project "$PROJECT" < "$FILE")
  REV=$(git ls-remote $URL | grep refs/heads/$BRANCH | awk '{print $1}')
  SHA256=$(nix-prefetch-git "$URL" "$REV" | jq -r '.sha256')
fi

TJQ=$(cat $FILE \
    | jq -rM ".[\"$PROJECT\"].rev = \"$REV\"" \
    | jq -rM ".[\"$PROJECT\"].sha256 = \"$SHA256\""
    )


if [[ $? == 0 ]]; then
  diff -u <(cat $FILE | jq -S .) <(echo "$TJQ" | jq -S .) || true
  echo "${TJQ}" >| "$FILE"
fi
