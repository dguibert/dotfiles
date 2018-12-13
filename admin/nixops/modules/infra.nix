let
  network = import <network>;

  defaults = network.defaults or [];

  # from ~/code/nixops/nix/eval-machine-info.nix
  # Compute the definitions of the machines.
  nodes = with (import <nixpkgs/lib>);
    listToAttrs (map (machineName:
      let
        # Get the configuration of this machine from each network
        # expression, attaching _file attributes so the NixOS module
        # system can give sensible error messages.
        modules =
          concatMap (n: optional (hasAttr machineName n)
            { imports = [(getAttr machineName n)]; inherit (n) _file; })
          [ network ];
      in
      { name = machineName;
        value = import <nixpkgs/nixos/lib/eval-config.nix> {
          modules =
            modules ++
            defaults;
	  extraArgs = { inherit nodes; name = machineName; };
        };
      }
    ) (attrNames (removeAttrs network [ "network" "defaults" "resources" "require" "_file" ])));
in
  nodes
