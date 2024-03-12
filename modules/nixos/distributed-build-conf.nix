# https://nixos.org/nix-dev/2015-September/018255.html
{ config, lib, pkgs, ... }:
{
  options.distributed-build-conf.enable = lib.mkEnableOption "distributed build";
  config = lib.mkIf config.distributed-build-conf.enable {
    #sops.secrets."id_buildfarm.pub".sopsFile = ../../secrets/defaults.yaml;
    users.extraUsers.nixBuild = {
      name = "nixBuild";
      useDefaultShell = true;
      #openssh.authorizedKeys.keyFiles = [ "${config.sops.secrets."id_buildfarm.pub".path}" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHV7fF2Ne3Frd+EQlyKgI5XRfq33WfacGLtUSXU+Yrg nixBuild"
      ];
      isSystemUser = true;
    };
    users.users.nixBuild.group = "nixBuild";
    users.groups.nixBuild = { };

    # on the client machine
    programs.ssh.extraConfig = ''
      Host rpi31
        HostName 192.168.1.13
        Port 22322
      Host rpi41
        HostName 192.168.1.14
        Port 22322
    '';
    nix.settings = {
      trusted-users = [ "nixBuild" "dguibert" ];
    };
    # 20181219 titan is now able to build aarch64 (binfmt and qemu-user)
    nix.distributedBuilds = true;
    nix.buildMachines = [
      #(lib.mkIf (config.networking.hostName != "rpi31") {
      #  hostName = "rpi31";
      #  maxJobs = 1;
      #  sshKey = "/etc/nix/id_nixBuild";
      #  sshUser = "nixBuild";
      #  system = "aarch64-linux";
      ##  supportedFeatures = [ "big-parallel" ];
      #})
      (lib.mkIf (config.networking.hostName != "rpi41") {
        hostName = "rpi41";
        maxJobs = 1;
        #speedFactor = 2;
        sshKey = "/etc/nix/id_buildfarm";
        sshUser = "nixBuild";
        system = "aarch64-linux";
        supportedFeatures = [ "big-parallel" ];
      })
    ];

    nix.settings.binary-cache-public-keys = [ "titan:dkOH0pvwo9CQMDs/H/Rs4HYEePVmwPf0/uSQi9ZmjxE=" ];
    nix.settings.trusted-binary-caches = [ "ssh-ng://titan" ];
  };
}
