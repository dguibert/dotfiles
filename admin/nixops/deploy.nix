{ nrNodes ? 0 # number of amazon nodes (but master)
, ...}@args:
{
  network.description = "NixOS Network";
  network.enableRollback = true;

  defaults = { nodes, ...}: {
    deployment.alwaysActivate = false;
  };

  orsine = { pkgs, config, ...}: {
    imports = [ ./orsine/configuration.nix ];
    deployment.targetHost = "10.147.17.123";
  };
}
