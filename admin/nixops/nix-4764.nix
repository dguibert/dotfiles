{ ca ? false }:
with import <nixpkgs> { };
let
  foo = runCommand "foo" { __contentAddressed = ca; } "echo foo > $out";
in
runCommand "bar" { } ''
  set -x
  [[ "${builtins.replaceStrings ["-"] ["+"] foo.outPath}" != ${foo.outPath} ]] || exit 1
  touch $out
''
