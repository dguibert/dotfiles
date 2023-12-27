{ config, lib, pkgs, ... }: {
  options.wayland-conf.enable = lib.mkEnableOption "wayland-conf";
  config = lib.mkIf config.wayland-conf.enable {
    nix.settings = {
      # add binary caches
      trusted-public-keys = [
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
      substituters = [
        "https://nixpkgs-wayland.cachix.org"
      ];
    };
    security.polkit.enable = true;
    security.pam.services.swaylock = { };
    hardware.opengl.enable = lib.mkDefault true;
    hardware.opengl.driSupport32Bit = true;
    fonts.enableDefaultPackages = lib.mkDefault true;
    fonts.fontDir.enable = true;
    fonts.enableGhostscriptFonts = true;
    fonts.fontconfig.enable = true;
    fonts.fontconfig.antialias = true;
    fonts.fontconfig.hinting.enable = true;
    fonts.packages = with pkgs ; [
      terminus_font
      powerline-fonts
      nerdfonts
      /*corefonts*/
      #noto-fonts
      #noto-fonts-cjk
      #noto-fonts-emoji
      #liberation_ttf
      #fira-code
      #fira-code-symbols
      #mplus-outline-fonts
      #dina-font
      #proggyfonts
    ];

    programs.dconf.enable = lib.mkDefault true;
    programs.xwayland.enable = lib.mkDefault true;

    xdg = {
      portal = {
        wlr.enable = true;
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    #services.greetd.enable = true;
    #services.greetd.settings = {
    #  default_session = {
    #    command = ''${pkgs.greetd.greetd}/bin/agreety --cmd "dwl -s somebar"'';
    #    #command = "${pkgs.greetd.wlgreet}/bin/wlgreet -e \"dwl -s somebar\"";
    #  };
    #};

    environment.systemPackages = with pkgs; [
      pavucontrol
      pulseaudio
    ];

    # Enable sound.
    # Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire
    #sound.enable = false;

    # rtkit is optional but recommended
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
      ## low-latency pulse backend https://nixos.wiki/wiki/PipeWire
      #config.pipewire-pulse = {
      #  "context.properties" = {
      #    "log.level" = 2;
      #  };
      #  "context.modules" = [
      #    {
      #      name = "libpipewire-module-rtkit";
      #      args = {
      #        "nice.level" = -15;
      #        "rt.prio" = 88;
      #        "rt.time.soft" = 200000;
      #        "rt.time.hard" = 200000;
      #      };
      #      flags = [ "ifexists" "nofail" ];
      #    }
      #    { name = "libpipewire-module-protocol-native"; }
      #    { name = "libpipewire-module-client-node"; }
      #    { name = "libpipewire-module-adapter"; }
      #    { name = "libpipewire-module-metadata"; }
      #    {
      #      name = "libpipewire-module-protocol-pulse";
      #      args = {
      #        "pulse.min.req" = "32/48000";
      #        "pulse.default.req" = "32/48000";
      #        "pulse.max.req" = "32/48000";
      #        "pulse.min.quantum" = "32/48000";
      #        "pulse.max.quantum" = "32/48000";
      #        "server.address" = [ "unix:native" ];
      #      };
      #    }
      #  ];
      #  "stream.properties" = {
      #    "node.latency" = "32/48000";
      #    "resample.quality" = 1;
      #  };
      #};
    };


  };
}

