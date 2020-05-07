# extra-builtins.nix
# https://elvishjerricco.github.io/2018/06/24/secure-declarative-key-management.html
# nix repl --option extra-builtins-file $(pwd)/extra-builtins.nix
# nix-repl> builtins.extraBuiltins.pass "secret-foo"
#
# deployment.keys.secret-foo.text = builtins.extraBuiltins.pass "secret-foo";
# destDir = "/secrets";
# nixops deploy -d my-deployment --option extra-builtins-file $(pwd)/extra-builtins.nix
{ exec ? builtins.exec or null, pkgs, ... }: let
  nix_pass = pkgs.writeScript "nix-pass.sh" ''
    #!/usr/bin/env bash

    # nix-pass.sh

    set -euo pipefail

    f=$(mktemp)
    trap "rm $f" EXIT
    pass show "$1" > $f
    nix-instantiate --eval -E "builtins.readFile $f"  '';

  is_git_decrypted = pkgs.writeScript "is-git-decrypted.sh" ''
    #!/usr/bin/env bash
    set -x
    decrypted=false
    case $(file --mime-type $1) in
      text/plain)
      decrypted=true;;
    esac
    nix-instantiate --eval -E "$decrypted"
  '';
in {
  pass_ = name: if builtins ? extraBuiltins && builtins.extraBuiltins ? pass
               then builtins.extraBuiltins.pass name
               else if exec != null
               then exec [ nix_pass name ]
               else "undefined";
  isGitDecrypted_ = name: if builtins ? extraBuiltins && builtins.extraBuiltins ? isGitDecrypted
               then builtins.trace "isGitDecrypted_ => isGitDecrypted" builtins.extraBuiltins.isGitDecrypted name
               else if exec != null
               then builtins.trace "isGitDecrypted_ => exec" exec [ is_git_decrypted name ]
               else builtins.trace "isGitDecrypted_ => false" false;

  extra_builtins_file = pkgs: pkgs.writeScript "extra-builtins-file.nix" ''
    {exec, ...}: {
      pass = name: exec [ ${nix_pass} name ];

      isGitDecrypted = name: exec [ ${is_git_decrypted} name ];
    }
  '';
}
