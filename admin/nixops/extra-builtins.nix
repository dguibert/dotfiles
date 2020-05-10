# extra-builtins.nix
# https://elvishjerricco.github.io/2018/06/24/secure-declarative-key-management.html
# nix repl --option extra-builtins-file $(pwd)/extra-builtins.nix
# nix-repl> builtins.extraBuiltins.pass "secret-foo"
#
# deployment.keys.secret-foo.text = builtins.extraBuiltins.pass "secret-foo";
# destDir = "/secrets";
# nixops deploy -d my-deployment --option extra-builtins-file $(pwd)/extra-builtins.nix
{ exec ? builtins.exec or null, pkgs, ... }: let
  makeProg = args: pkgs.substituteAll (args // {
    dir = "bin";
    isExecutable = true;
  });

  nix_pass = makeProg {
    name = "nix-pass";
    src = ./extra-builtins/nix-pass.sh;
  };

  is_git_decrypted = makeProg {
    name = "is-git-decrypted";
    src = ./extra-builtins/is-git-decrypted.sh;
  };

  ### https://www.lorier.net/docs/ssh-ca.html
  ssh_generate_ca = makeProg {
    name = "ssh-generate-ca";
    src = ./extra-builtins/ssh-generate-ca.sh;
  };
  # On the server that's being authenticated: for i in /etc/ssh/ssh_host*_key-cert.pub; do echo "HostCertificate $i" >>/etc/ssh/sshd_config done
  # System wide: echo "@cert-authority * $(cat /etc/ssh/ca.pub)" >>/etc/ssh/ssh_known_hosts
  # Per user: echo "@cert-authority * $(cat /etc/ssh/ca.pub)" >>~/.ssh/known_hosts
  ssh_sign_host = makeProg {
    name = "ssh-sign-host";
    src = ./extra-builtins/ssh-sign-host.sh;
    inherit ssh_generate_ca;
  };

  ssh_sign_user = "";

  # user
  #* System wide:
  #  echo "AuthorizedPrincipalsFile %h/.ssh/authorized_principals" >>/etc/ssh/sshd_config
  #  echo "TrustedUserCAKeys /etc/ssh/ca.pub" >>/etc/ssh/sshd_config
  #  echo $(whoami) > ~/.ssh/authorized_principals
  #* Per user: echo "cert-authority,principals=$(whoami) $(cat /etc/ssh/ca.pub)" >>~/.ssh/authorized_keys

  # to revoke keys
  #* System wide:
  # echo "RevokedKeys /etc/ssh/revoked_keys" >>/etc/ssh/sshd_config
  # ssh-keygen -k -f /etc/ssh/revoked_keys $public_key_to_revoke
  # ssh-keygen -k -u -f /etc/ssh/revoked_keys $additional_public_keys_to_revoke
  # or:
  # echo "RevokedKeys /etc/ssh/revoked_keys" >>/etc/ssh/sshd_config
  # echo @revoked $(cat $public_key_to_revoke) >> /etc/ssh/revoked_keys
  #* Per user: echo @revoked $(cat $public_key_to_revoke) >>~/.ssh/known_hosts

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

  sshSignHost_ = ca: hostname: realms: type: if builtins ? extraBuiltins && builtins.extraBuiltins ? sshSignHost
               then builtins.trace "sshSignHost_ => sshSignHost" builtins.extraBuiltins.sshSignHost ca hostname realms type
               else if exec != null
               then builtins.trace "sshSignHost_ => exec" exec [ ssh_sign_host ca hostname realms type ]
               else builtins.trace "sshSignHost_ => ''" { host_key=""; host_key_pub=""; host_key_cert_pub=""; };

  extra_builtins_file = pkgs: pkgs.writeScript "extra-builtins-file.nix" ''
    {exec, ...}: {
      pass = name: exec [ ${nix_pass} name ];

      isGitDecrypted = name: exec [ ${is_git_decrypted} name ];

      sshSignHost = ca: hostname: realms: type: exec [ ${ssh_sign_host} ca hostname realms type ];
      sshSignUser = ca: username: realms: type: exec [ ${ssh_sign_user} ca username realms type ];
    }
  '';
}
