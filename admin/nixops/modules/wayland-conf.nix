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
    security.pam.services.swaylock = {};
    hardware.opengl.enable = lib.mkDefault true;
    hardware.opengl.driSupport32Bit = true;
    fonts.enableDefaultFonts = lib.mkDefault true;
    fonts.fontDir.enable = true;
    fonts.enableGhostscriptFonts = true;
    fonts.fontconfig.enable = true;
    fonts.fontconfig.antialias = true;
    fonts.fontconfig.hinting.enable = true;
    fonts.fonts = with pkgs ; [
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

    xdg.portal.wlr.enable = true;
    #services.greetd.enable = true;
    #services.greetd.settings = {
    #  default_session = {
    #    command = ''${pkgs.greetd.greetd}/bin/agreety --cmd "dwl -s somebar"'';
    #    #command = "${pkgs.greetd.wlgreet}/bin/wlgreet -e \"dwl -s somebar\"";
    #  };
    #};
  };
}

