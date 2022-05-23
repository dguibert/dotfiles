{ config, pkgs, lib, ... }:

let

  # https://git.sr.ht/~raphi/dwl/tree/master/item/dwl-session
  dwl-session = pkgs.writeShellScriptBin "dwl-session" ''
    #!/bin/sh
    set -e
    maybe() {
      command -v "$1" > /dev/null && "$@"
    }

    if [ "$1" = 'startup' ]; then
      # this is hell
      dbus-update-activation-environment --systemd \
        QT_QPA_PLATFORM WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

      #maybe ~/.local/lib/pulseaudio-watch someblocks &
      PATH=~/code/someblocks:$PATH someblocks &
      swaybg -i ~/Pictures/wallpaper.png -o '*' -m fit &
      somebar

      # kill any remaining background tasks
      for pid in $(pgrep -g $$); do
        test "$$" != "$pid" && kill "$pid"
      done
    else
      if [ -e /dev/nvidiactl ]; then
        export WLR_NO_HARDWARE_CURSORS=1
      fi
      export QT_QPA_PLATFORM=wayland-egl
      export XDG_CURRENT_DESKTOP=wlroots

      # Start systemd user services for graphical sessions
      /run/current-system/systemd/bin/systemctl --user start graphical-session.target

      exec dwl -s "setsid -w $0 startup <&-" |& tee ~/dwl-session.log ; history -n # close standard input
    fi
  '';

  # https://git.sr.ht/~raphi/dotfiles/tree/nixos/item/.local/lib/pulseaudio-watch

  wlr-toggle = pkgs.writeShellScriptBin "wlr-toggle" ''
    #!/bin/sh

    ''${VERBOSE:-true} && set -x
    arg=''${1:-}
    export PATH=''${PATH+$PATH:}${pkgs.wlr-randr}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin
    command -v wlr-randr
    toggle_file=/run/user/$(id -u)/toggle_outputs

    if [ "$arg" = "on" ]; then
      if [ -e $toggle_file ]; then
        options=""
        for output in $(cat $toggle_file); do
          options+=" --output $output --''${arg:-on}"
        done
        wlr-randr $options
        rm $toggle_file
      fi
    else
      outputs=$(wlr-randr | awk '$1 ~ /^[A-Za-z-]+-[1-9]/ { output=$1; } /Enabled: yes/ { print output } { next; } ')
      echo $outputs > $toggle_file
      for output in $(cat $toggle_file); do
        options+=" --output $output --''${arg:-off}"
      done
      wlr-randr $options
    fi
  '';

in with lib; {

  home.packages = with pkgs; [
    dwl-session
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

  #systemd.user.services.dwl = {
  #  Unit = {
  #    Description = "DWL - Wayland window manager";
  #    BindsTo = [ "graphical-session.target" ];
  #    Wants = [ "graphical-session-pre.target" ];
  #    After = [ "graphical-session-pre.target" ];
  #  };
  #  Service = {
  #    Type = "simple";
  #    ExecStart = "${pkgs.dwl}/bin/dwl -s ${pkgs.somebar}/bin/somebar";
  #    Restart = "on-failure";
  #    RestartSec = 1;
  #    TimeoutStopSec = 10;
  #  };
  #};

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
      ExecStart = "${pkgs.swayidle}/bin/swayidle -d -w timeout 300 '${pkgs.swaylock}/bin/swaylock -f -c 000000' timeout 360 '${wlr-toggle}/bin/wlr-toggle off' resume '${wlr-toggle}/bin/wlr-toggle on' before-sleep '${pkgs.swaylock}/bin/swaylock -f -c 000000'";
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
    profile {
      output DVI-D-1 mode 1920x1080 position 0,0
      output HDMI-A-1 mode 1920x1080 position 1920,0
    }
    profile {
      output eDP-1 mode 1920x1080 position 0,0
    }
    profile {
      output "Lenovo Group Limited LEN T24d-10 V5GG2005" mode 1920x1080 position 0,0
      output eDP-1 mode 1920x1080 position 1920,0
    }
    profile {
      output "Philips Consumer Electronics Company PHL 241B7QG 0x000004CC" mode 1920x1080 position 0,0
      output eDP-1 mode 1920x1080 position 1920,0
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
