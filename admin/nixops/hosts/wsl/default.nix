{ config, lib, inputs, withSystem, self, ... }:
{
  options.modules.hosts.wsl = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
  };

  config.modules.hosts.wsl = [
    inputs.nixos-wsl.nixosModules.wsl
    ({ ... }: {
      wsl.enable = true;
      wsl.defaultUser = "dguibert";
      wsl.startMenuLaunchers = true;

      programs.bash.loginShellInit = "nixos-wsl-welcome";
    })
    ../../modules/nixos/nix-conf.nix
    inputs.home-manager.nixosModules.home-manager
    ../../users/dguibert
    ({ pkgs, ... }: {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "hm-backup";
      home-manager.extraSpecialArgs = {
        inherit inputs pkgs;
        sopsDecrypt_ = pkgs.sopsDecrypt_;
      };

      i18n = {
        supportedLocales = [ "en_US.UTF-8/UTF-8" ];
      };

      home-manager.users.dguibert = {
        imports = [
          ({ config, pkgs, ... }: {
            imports = [
              ../../modules/home-manager/dguibert.nix
            ];
            withGui.enable = false;
            withEmacs.enable = true;
            home.homeDirectory = "/home/dguibert";
            home.stateVersion = "23.05";
          })
        ];
      };
    })

  ];

  config.flake.nixosConfigurations = withSystem "x86_64-linux" ({ system, ... }: {
    wsl = inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        pkgs = self.legacyPackages.${system};
        inherit inputs;
      };
      modules = config.modules.hosts.wsl;
    };
  });
}

