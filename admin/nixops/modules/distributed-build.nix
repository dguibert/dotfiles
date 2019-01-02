# https://nixos.org/nix-dev/2015-September/018255.html
{ config, lib, pkgs, ... }:
{
  users.extraUsers.nixBuild = {
    name = "nixBuild";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHV7fF2Ne3Frd+EQlyKgI5XRfq33WfacGLtUSXU+Yrg nixBuild" ];
  };
  # on the client machine
  programs.ssh.extraConfig = ''
    Host rpi31
      HostName 192.168.1.13
      Port 22322
  '';
  nix = {
    trustedUsers = [ "nixBuild" "dguibert" ];
    # 20181219 titan is now able to build aarch64 (binfmt and qemu-user)
    distributedBuilds = true;
    buildMachines = [{
      hostName = "rpi31";
      maxJobs = 4;
      sshKey = "/root/.ssh/id_nixBuild";
      sshUser = "nixBuild";
      system = "aarch64-linux";
    #  supportedFeatures = [ "big-parallel" ];
    }];
  };
}
