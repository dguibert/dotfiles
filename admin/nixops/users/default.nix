{ sopsDecrypt_, pkgs, inputs, ...}@args:
{ ... }: {
  imports = [
    (import ./root/default.nix args)
    (import ./dguibert/default.nix args)
  ];
}
