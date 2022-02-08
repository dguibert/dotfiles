{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    terranix = {
      url = "github:mrVanDalo/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, terranix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        terraform = pkgs.terraform_0_15.withPlugins (p: with p; [
          libvirt
          #random
          #external
          #template
          #p."null"
        ]);

        terraformConfiguration = terranix.lib.terranixConfiguration {
          inherit system pkgs;
          strip_nulls = false;
          modules = [ ./config.nix ];
        };
      in {
        defaultPackage = terraformConfiguration;
        # nix develop
        devShell = pkgs.mkShell {
          ENVRC = "terraform";
          buildInputs = [
            terraform
            terranix.defaultPackage.${system}
          ];
        };
        # nix run ".#apply"
        apps.apply = {
          type = "app";
          program = toString (pkgs.writers.writeBash "apply" ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
            cp ${terraformConfiguration} config.tf.json \
              && ${terraform}/bin/terraform init \
              && ${terraform}/bin/terraform apply
          '');
        };
        # nix run ".#destroy"
        apps.destroy = {
          type = "app";
          program = toString (pkgs.writers.writeBash "destroy" ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
            cp ${terraformConfiguration} config.tf.json \
              && ${terraform}/bin/terraform init \
              && ${terraform}/bin/terraform destroy
          '');
        };
        # nix run ".#plan"
        apps.plan = {
          type = "app";
          program = toString (pkgs.writers.writeBash "destroy" ''
            if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
            cp ${terraformConfiguration} config.tf.json \
              && ${terraform}/bin/terraform init \
              && ${terraform}/bin/terraform plan
          '');
        };
        # nix run
        defaultApp = self.apps.${system}.apply;
  }) // (let
    in {
      # architecture agnostic attributes
  });
}
