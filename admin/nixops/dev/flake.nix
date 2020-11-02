{
  description = "Configurations of my systems";


  # To update all inputs:
  # $ nix flake update --recreate-lock-file
  inputs = {
    home-manager. url    = "github:dguibert/home-manager/pu";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hydra.url            = "github:dguibert/hydra/pu";
    hydra.inputs.nix.follows = "nix";
    hydra.inputs.nixpkgs.follows = "nixpkgs";

    nixops.url           = "github:dguibert/nixops/pu";
    #nixops.inputs.nixpkgs.follows = "nixpkgs";
    #nixops.inputs.utils.follows = "flake-utils";

    nixpkgs.url          = "git+file:///home/dguibert/code/nixpkgs";

    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nur_dguibert.url= "git+file:///home/dguibert/nur-packages";
    nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
    nur_dguibert.inputs.nix.follows = "nix";
    nur_dguibert.inputs.flake-utils.follows = "flake-utils";
    #nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
    #nur_dguibert_envs.url= "git+file:///home/dguibert/nur-packages?dir=envs";
    #nur_dguibert_envs.inputs.nixpkgs.follows = "nixpkgs";
    #nur_dguibert_envs.inputs.nix.follows     = "nix";
    terranix             = { url = "github:mrVanDalo/terranix"; flake=false; };

    base16-nix           = { url  = "github:atpotts/base16-nix"; flake=false; };
    gitignore            = { url  = "github:hercules-ci/gitignore"; flake=false; };

    nxsession.url           = "github:dguibert/nxsession";
    nxsession.inputs.nixpkgs.follows = "nixpkgs";
    nxsession.inputs.flake-utils.follows = "flake-utils";
  };

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs: {};
}
