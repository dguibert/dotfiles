{ config, lib, pkgs, ... }:

let
  cfg = config.role.libvirtd;
in
{
  options.role.libvirtd.enable = lib.mkOption {
    default = false;
    description = "Whether to enable libvirtd";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    # https://nixos.wiki/wiki/Virt-manager
    # https://nixos.org/nixops/manual/#idm140737318329504
    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.qemu = {
      #ovmf.package = pkgs.OVMF.override { secureBoot=true; tpmSupport=true; };
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
      swtpm.enable = true;
      verbatimConfig = ''
        memory_backing_dir = "/dev/shm"
      '';
    };
    # https://github.com/NixOS/nixpkgs/issues/75878
    systemd.services.libvirtd.environment.EBTABLES_PATH = "${pkgs.ebtables}/bin/ebtables-legacy";
    # https://github.com/NixOS/nixpkgs/pull/35214#pullrequestreview-97783209
    security.wrappers.spice-client-glib-usb-acl-helper = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
    };

    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [
      virt-manager
    ] ++ lib.optionals config.virtualisation.libvirtd.qemu.swtpm.enable [
      config.virtualisation.libvirtd.qemu.swtpm.package
    ];

    systemd.tmpfiles.rules = [ "d /var/lib/libvirt/images 1770 root libvirtd -" ];
  };
}
