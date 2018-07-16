# https://github.com/snabblab/snabblab-nixos/blob/master/make-iso.nix
# build an ISO image that will auto install NixOS and reboot
# $ nix-build make-iso.nix

let
   config = (import <nixpkgs/nixos/lib/eval-config.nix> {
     system = "x86_64-linux";
     modules = [
	<nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
       ({ pkgs, lib, ... }:
         let
           cfg = pkgs.writeText "configuration.nix" ''
            { config, pkgs, lib, ... }:

            {
              boot.loader.grub.enable = true;
              boot.loader.grub.devices = [ "/dev/sda" ];
              boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "ehci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];

              i18n.consoleKeyMap = "fr";
              services.openssh.enable = true;
              users.extraUsers.root.initialPassword = lib.mkForce "OhPha3gu";
              users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
           ];

              # Select internationalisation properties.
              i18n.consoleFont = "Lat2-Terminus16";
              i18n.consoleKeyMap = "fr";
              i18n.defaultLocale = "en_US.UTF-8";

              # Set your time zone.
              time.timeZone = "Europe/Paris";

              # this is set for install not to ask for password
              users.mutableUsers = false;

	      fileSystems = [
		{ mountPoint="/"; fstype = "ext4"; label = "root" }
	      ];
            }
           '';
           partitions = pkgs.writeText "partitions" ''
             clearpart --all --initlabel --drives=sda
             part swap --size=512 --ondisk=sda
             part / --fstype=ext4 --label=root --grow --ondisk=sda
           '';
         in {
           i18n.consoleKeyMap = "fr";
           users.extraUsers.root.initialPassword = lib.mkForce "OhPha3gu";
           users.users.root.openssh.authorizedKeys.keys = [
    "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
           ];
           # Select internationalisation properties.
           i18n.consoleFont = "Lat2-Terminus16";
           i18n.consoleKeyMap = "fr";
           i18n.defaultLocale = "en_US.UTF-8";

           # Set your time zone.
           time.timeZone = "Europe/Paris";

          # systemd.services.inception = {
          #   description = "Self-bootstrap a NixOS installation";
          #   wantedBy = [ "multi-user.target" ];
          #   after = [ "network.target" "polkit.service" ];
          #   # TODO: submit a patch for blivet upstream to unhardcode kmod/e2fsprogs/utillinux
          #   path = [ "/run/current-system/sw/" ];
          #   script = with pkgs; ''
          #     sleep 5
          #     ${pythonPackages.nixpart0}/bin/nixpart ${partitions}
          #     mkdir -p /mnt/etc/nixos/
          #     cp ${cfg} /mnt/etc/nixos/configuration.nix
          #     ${config.system.build.nixos-install}/bin/nixos-install -j 4
          #     ${systemd}/bin/shutdown -r now
          #   '';
          #   environment = config.nix.envVars // {
          #     inherit (config.environment.sessionVariables) NIX_PATH SSL_CERT_FILE;
          #     HOME = "/root";
          #   };
          #   serviceConfig = {
          #     Type = "oneshot";
          #   };
          #};
       })
     ];
   }).config;
in
  config.system.build.isoImage
