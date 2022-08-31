# nix-build nix-builtins-exec.nix --arg ca false --option allow-unsafe-native-code-during-evaluation true
# => ok
# nix-build nix-builtins-exec.nix --arg ca true  --option allow-unsafe-native-code-during-evaluation true
# => fails
{ ca ? false }:
with import <nixpkgs> { };
let
  foo = runCommand "foo" { __contentAddressed = ca; } ''
    cat > $out <<EOF
      #/bin/sh
      echo '"foo"'
    EOF
    chmod +x $out
  ''; #"echo foo > $out";
in
runCommand "bar" { } ''
  set -x
  [[ "${builtins.exec [ foo ]}" != '"foo"' ]] || exit 1
  touch $out
''
