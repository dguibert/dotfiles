{ config, lib, inputs, withSystem, self, ... }:
let
  genHomeManagerConfiguration = import ../lib/gen-home-manager-configuration.nix { inherit lib; };
in
{
  imports = [
    (genHomeManagerConfiguration "aarch64-linux" "dguibert@rpi31")
    (genHomeManagerConfiguration "aarch64-linux" "dguibert@rpi41")
    (genHomeManagerConfiguration "x86_64-linux" "dguibert@t580")
    (genHomeManagerConfiguration "x86_64-linux" "dguibert@titan")

    (genHomeManagerConfiguration "x86_64-linux" "bguibertd@spartan")
    (genHomeManagerConfiguration "x86_64-linux" "bguibertd@spartan-x86_64")
    #(genHomeManagerConfiguration "aarch64-linux" "bguibertd@spartan-aarch64")
    (genHomeManagerConfiguration "x86_64-linux" "bguibertd@spartan-aarch64")
  ];

  modules.homes."dguibert@rpi31" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/home-manager/dguibert.nix
      ];
      withGui.enable = false;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

  modules.homes."dguibert@rpi41" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/home-manager/dguibert.nix
      ];
      withGui.enable = true;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";
    })
  ];

  modules.homes."dguibert@t580" = [
    ../modules/home-manager/dguibert.nix
    ({ config, pkgs, ... }: {
      #wayland.windowManager.hyprland.enable = true;
      #wayland.windowManager.hyprland.package = pkgs.hyprland;
      withGui.enable = true;
      withEmacs.enable = true;
      withZellij.enable = true;
      #withVSCode.enable = true;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";

      programs.direnv.enable = true;
      programs.direnv.nix-direnv.enable = true;
    })
  ];

  modules.homes."dguibert@titan" = [
    ../modules/home-manager/dguibert.nix
    ({ config, pkgs, ... }: {
      #wayland.windowManager.hyprland.enable = true;
      centralMailHost.enable = true;
      withGui.enable = true;
      hyprland.nvidia.enable = true;
      withEmacs.enable = true;
      withZellij.enable = true;
      home.username = "dguibert";
      home.homeDirectory = "/home/dguibert";
      home.stateVersion = "22.11";

      programs.direnv.enable = true;
      programs.direnv.nix-direnv.enable = true;
    })
  ];

  modules.homes."bguibertd@spartan" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/home-manager/dguibert.nix
        ../modules/home-manager/dguibert/custom-profile.nix
      ];
      centralMailHost.enable = false;
      withGui.enable = false;
      withCustomProfile.enable = true;
      withCustomProfile.suffix = "";

      home.username = "bguibertd";
      home.homeDirectory = "/home_nfs/bguibertd";
      home.stateVersion = "22.11";
      #home.activation.setNixVariables = lib.hm.dag.entryBefore ["writeBoundary"]

      # don't use full bash config
      withBash.enable = false;
      programs.bash.enable = true;
      programs.bash.historySize = -1; # no truncation
      programs.bash.historyFile = "$HOME/.bash_history";
      programs.bash.historyFileSize = -1; # no truncation
      programs.bash.historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      programs.bash.historyIgnore = [
        "ls"
        "cd"
        "clear"
        "[bf]g"
        " *"
        "cd -"
        "history"
        "history -*"
        "pwd"
        "exit"
        "date"
      ];

      programs.bash.bashrcExtra = /*(homes.withoutX11 args).programs.bash.initExtra +*/ ''
        # support for x86_64/aarch64
        # include .bashrc if it exists
        [[ -f ~/.bashrc.$(uname -m) ]] && . ~/.bashrc.$(uname -m)
      '';
      programs.bash.profileExtra = ''
        # support for x86_64/aarch64
        # include .profile if it exists
        [[ -f ~/.profile.$(uname -m) ]] && . ~/.profile.$(uname -m)
      '';

      home.packages = with pkgs; [
        dtach
      ];
    })
  ];

  modules.homes."bguibertd@spartan-x86_64" = [
    ({ config, pkgs, ... }: {
      imports = [
        ../modules/home-manager/dguibert.nix
        ../modules/home-manager/dguibert/custom-profile.nix
      ];
      centralMailHost.enable = false;
      withGui.enable = false;
      withCustomProfile.enable = true;
      withCustomProfile.suffix = "x86_64";
      withEmacs.enable = true;

      home.username = "bguibertd";
      home.homeDirectory = "/home_nfs/bguibertd";
      home.stateVersion = "22.11";

      home.sessionPath = [
        "${pkgs.nix}/bin"
      ];

      home.packages = with pkgs; [
        xpra
        bashInteractive

        datalad
        git-annex
        git-nomad
        mr
        subversion

        tig
        python3
      ];

      home.sessionVariables.NIX_SSL_CERT_FILE = "/etc/pki/tls/certs/ca-bundle.crt";
      home.sessionVariables.TMP = "/dev/shm";

      programs.direnv.enable = true;
      programs.direnv.nix-direnv.enable = true;
    })
  ];

  modules.homes."bguibertd@spartan-aarch64-cross-system" = "aarch64-multiplatform";
  modules.homes."bguibertd@spartan-aarch64" = [
    ({ config, pkgs, lib, ... }: {
      imports = [
        ../modules/home-manager/dguibert.nix
        ../modules/home-manager/dguibert/custom-profile.nix
      ];
      centralMailHost.enable = false;
      withGui.enable = false;
      withCustomProfile.enable = true;
      withCustomProfile.suffix = "aarch64";
      withEmacs.enable = false;
      withBash.history-merge = false;
      services.gpg-agent.enable = lib.mkForce false;

      home.username = "bguibertd";
      home.homeDirectory = "/home_nfs/bguibertd";
      home.stateVersion = "22.11";

      home.sessionPath = [
        "${pkgs.nix}/bin"
      ];

      _module.args.activationPkgs = pkgs.buildPackages;
      home.packages = with pkgs; [
        bashInteractive
      ];
    })
  ];

}


