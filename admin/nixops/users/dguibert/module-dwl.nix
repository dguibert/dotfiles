{ config, pkgs, ... }:

let

  start-dwl = pkgs.writeShellScriptBin "start-dwl" ''
    # first import environment variables from the login manager
    systemctl --user import-environment XDG_SEAT WAYLAND_DISPLAY
    # then start the service
    exec systemctl --user start dwl.service
  '';

  start-waybar = pkgs.writeShellScriptBin "start-waybar" ''
    export SWAYSOCK=/run/user/$(id -u)/sway-ipc.$(id -u).$(pgrep -f 'sway$').sock
    ${pkgs.waybar}/bin/waybar
  '';

in {

  home.packages = with pkgs; [
    start-dwl
    dwl
    somebar
    wl-clipboard
    alacritty # Alacritty is the default terminal in the config
    dmenu-wayland # Dmenu is the default in the config but i recommend wofi since its wayland native
    swaylock # lockscreen
    swayidle
    wlr-randr
    xwayland # for legacy apps
    mako # notification daemon
    kanshi # autorandr
    brightnessctl

    waypipe
    grim
    slurp
    wayvnc
  ];

  systemd.user.sockets.dbus = {
    Unit = {
      Description = "D-Bus User Message Bus Socket";
    };
    Socket = {
      ListenStream = "%t/bus";
      ExecStartPost = "${pkgs.systemd}/bin/systemctl --user set-environment DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
    };
    Install = {
      WantedBy = [ "sockets.target" ];
      Also = [ "dbus.service" ];
    };
  };

  systemd.user.services.dbus = {
    Unit = {
      Description = "D-Bus User Message Bus";
      Requires = [ "dbus.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.dbus}/bin/dbus-daemon --session --address=systemd: --nofork --nopidfile --systemd-activation";
      ExecReload = "${pkgs.dbus}/bin/dbus-send --print-reply --session --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig";
    };
    Install = {
      Also = [ "dbus.socket" ];
    };
  };

  systemd.user.services.dwl = {
    Unit = {
      Description = "DWL - Wayland window manager";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.dwl}/bin/dwl -s ${pkgs.somebar}/bin/somebar";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.mako}/bin/mako";
      RestartSec = 5;
      Restart = "always";
    };
  };

  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle display configuration";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 300 '${pkgs.swaylock}/bin/swaylock -f -c 000000' timeout 360 '${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --off' resume '${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --on' before-sleep '${pkgs.swaylock}/bin/swaylock -f -c 000000'";
      RestartSec = 5;
      Restart = "always";
    };
  };

  systemd.user.services.kanshi = {
    Unit = {
      Description = "Kanshi dynamic display configuration";
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi";
      RestartSec = 5;
      Restart = "always";
    };
  };

  xdg.configFile."kanshi/config".text = ''
    {
      output eDP-1 mode 1920x1080 position 0,0
    }
  '';

  #systemd.user.services.someblocks = {
  #  Unit = {
  #    Description = "someblocks";
  #    PartOf = [ "graphical-session.target" ];
  #  };
  #  Install = {
  #    WantedBy = [ "graphical-session.target" ];
  #  };
  #  Service = {
  #    Type = "simple";
  #    ExecStart = "${pkgs.someblocks}/bin/someblocks";
  #    RestartSec = 5;
  #    Restart = "always";
  #  };
  #};

}
