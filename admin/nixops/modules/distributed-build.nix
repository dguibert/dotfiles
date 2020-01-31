# https://nixos.org/nix-dev/2015-September/018255.html
{ config, lib, pkgs, ... }:
{
  users.extraUsers.nixBuild = {
    name = "nixBuild";
    useDefaultShell = true;
    openssh.authorizedKeys.keyFiles = [ ../id_buildfarm.pub ];
  };
  # on the client machine
  programs.ssh.extraConfig = ''
    Host rpi31
      HostName 192.168.1.13
      Port 22322
    Host rpi41
      HostName 192.168.1.14
      Port 22322
  '';
  nix = {
    trustedUsers = [ "nixBuild" "dguibert" ];
    # 20181219 titan is now able to build aarch64 (binfmt and qemu-user)
    distributedBuilds = true;
    buildMachines = [
    (lib.mkIf (config.networking.hostName != "rpi31") {
      hostName = "rpi31";
      maxJobs = 1;
      sshKey = "/etc/nix/id_nixBuild";
      sshUser = "nixBuild";
      system = "aarch64-linux";
    #  supportedFeatures = [ "big-parallel" ];
    })
    (lib.mkIf (config.networking.hostName != "rpi41") {
      hostName = "rpi41";
      maxJobs = 4;
      sshKey = "/etc/nix/id_nixBuild";
      sshUser = "nixBuild";
      system = "aarch64-linux";
      supportedFeatures = [ "big-parallel" ];
    })
    ];
  };

  nix.binaryCachePublicKeys = [ "titan:dkOH0pvwo9CQMDs/H/Rs4HYEePVmwPf0/uSQi9ZmjxE=" ];
  nix.trustedBinaryCaches = [ "ssh-ng://titan" ];
}
