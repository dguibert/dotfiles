{ config, pkgs, lib, ... }:

{
          boot.loader.grub.enable = true;
          boot.loader.grub.devices = [ "/dev/sda" "/dev/sdb" ];
          boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "ehci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
          boot.kernelModules = [ "kvm-intel" ];
          boot.extraModulePackages = [ ];

          boot.supportedFilesystems = [ "zfs" ];
          networking.hostId="8425e349";

          services.openssh.enable = true;
          services.openssh.startWhenNeeded = true;
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
          environment.systemPackages = with pkgs; [ vim git ];

          fileSystems."/" =
  { device = "rpool/root/nixos";
    fsType = "zfs";
  };

fileSystems."/home" =
  { device = "rpool/home";
    fsType = "zfs";
  };

  nix.maxJobs = lib.mkDefault 2;
}

