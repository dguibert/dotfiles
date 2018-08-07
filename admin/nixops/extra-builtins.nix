# extra-builtins.nix
# https://elvishjerricco.github.io/2018/06/24/secure-declarative-key-management.html
# nix repl --option extra-builtins-file $(pwd)/extra-builtins.nix
# nix-repl> builtins.extraBuiltins.pass "secret-foo"
#
# deployment.keys.secret-foo.text = builtins.extraBuiltins.pass "secret-foo";
# destDir = "/secrets";
# nixops deploy -d my-deployment --option extra-builtins-file $(pwd)/extra-builtins.nix
{ exec, ... }: {
  pass = name: exec [./nix-pass.sh name];
}
