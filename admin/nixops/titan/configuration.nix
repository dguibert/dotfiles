{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    grub = {
       efiSupport = true;
       #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
       device = "nodev";
    };
  };

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
  fileSystems."/boot/efi".label = "EFI";
  networking.hostName = "titan"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

  #  networking.wireguard.interfaces.wg0 = {
  #    ips = [ "10.147.27.24/24" ];
  #    listenPort = 500;
  #    privateKeyFile = "/secrets/wireguard_key";
  #    peers = [
  #      { allowedIPs = [ "10.147.27.0/24" ];
  #        publicKey  = "wBBjx9LCPf4CQ07FKf6oR8S1+BoIBimu1amKbS8LWWo=";
  #        endpoint   = "83.155.85.77:500";
  #      }
  #      { allowedIPs = [ "10.147.27.198/32" ];
  #        publicKey  = "rbYanMKQBY/dteQYQsg807neESjgMP/oo+dkDsC5PWU=";
  #        endpoint   = "orsin.freeboxos.fr:51821";
  #	#persistentKeepalive = 25;
  #      }
  #      { allowedIPs = [ "10.147.27.128/32" ];
  #        publicKey  = "apJCCchRSbJnTH6misznz+re4RYTxfltROp4fbdtGzI=";
  #        endpoint   = "192.168.1.45:500";
  #      }
  #      { allowedIPs = [ "10.147.27.123/32" ];
  #        publicKey  = "Z8yyrih3/vINo6XlEi4dC5i3wJCKjmmJM9aBr4kfZ1k=";
  #        endpoint   = "orsin.freeboxos.fr:51820";
  #      }
  #    ];
  #  };
  #  networking.firewall.allowedUDPPorts = [ 500 ];

}
