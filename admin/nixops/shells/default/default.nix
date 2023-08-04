{ config, lib, inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      inherit inputs;
      inherit (inputs.sops-nix.packages.${system}) sops-import-keys-hook ssh-to-pgp;
      deploy-rs = pkgs.deploy-rs.deploy-rs;
      pre-commit-check-shellHook = inputs.self.checks.${system}.pre-commit-check.shellHook;
    in
    {
      devShells.default = pkgs.mkShell rec {
        name = "deploy";
        ENVRC = name;

        # imports all files ending in .asc/.gpg and sets $SOPS_PGP_FP.
        #sopsPGPKeyDirs = [
        ##  #"./keys/hosts"
        ##  #"./keys/users"
        #];
        # Also single files can be imported.
        sopsPGPKeys = [
          "./keys/hosts/titan.asc"
          "./keys/hosts/rpi41.asc"
          "./keys/hosts/rpi31.asc"
          "./keys/hosts/t580.asc"
          "./keys/users/dguibert.asc"
        ];
        buildInputs = with pkgs; [
          ssh-to-pgp
          ssh-to-age
          deploy-rs.deploy-rs
          #nix-diff # Package nix-diff in /nix/store/1bzvzc4q4dr11h1zxrspmkw54s7jpip8-source/pkgs/development/haskell-modules/hackage-packages.nix:174705 is marked as broken, refusing to evaluate.

          #jq
          #step-ca
          #step-cli
          #yubikey-manager
          #pcsclite
          #opensc

          #nix-output-monitor
        ];
        nativeBuildInputs = [
          sops-import-keys-hook
        ];
        #SOPS_PGP_FP = "";
        sopsCreateGPGHome = "";
        shellHook = ''
          test -e .git || export GIT_DIR=$HOME/.mgit/dotfiles/.git
          rm -f ~/.pre-commit-config.yaml
          ${pre-commit-check-shellHook}
          ln -s ~/.pre-commit-config.yaml .

          unset NIX_INDENT_MAKE
          unset IN_NIX_SHELL NIX_REMOTE
          unset TMP TMPDIR

          unset NIX_STORE NIX_DAEMON

          export PASSWORD_STORE_DIR=$PWD/secrets
        '';

      };
    };
}
