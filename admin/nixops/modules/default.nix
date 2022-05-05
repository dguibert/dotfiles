{
  distributed-build-conf = import ./distributed-build-conf.nix;
  nix-conf = import ./nix-conf.nix;
  report-changes = import ./report-changes.nix;
  wireguard-mesh = import ./wireguard-mesh.nix;
  x11-conf = import ./x11-conf.nix;
  yubikey-gpg-conf = import ./yubikey-gpg-conf.nix;
  zfs = import ./zfs.nix;
}
