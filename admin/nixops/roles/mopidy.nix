{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.role.mopidy-server;

  silence_mp3 = pkgs.fetchurl {
    url = "https://github.com/anars/blank-audio/blob/master/500-milliseconds-of-silence.mp3";
    sha256 = "sha256-7uonhOBLY9JNQPgNcv1ec92GRoPP3MY7nPj3ygu+n/s=";
  };
  webroot = pkgs.runCommand "icecast-webroot" {} ''
    mkdir $out
    cp -v ${pkgs.icecast}/share/icecast/web/* $out
    cp -v ${silence_mp3} $out/silence.mp3
  '';
in {
  options = {
    role.mopidy-server = {
      enable = mkEnableOption "Enable a mopidy server";
      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "any";
        description = ''
          The address for the daemon to listen on.
          Use <literal>any</literal> to listen on all addresses.
        '';
      };
      configuration = mkOption {
        type = types.attrsOf (types.attrsOf types.unspecified);
        default = {};
        description = ''
          Key-value pairs that convey parameters about the configuration
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    role.mopidy-server.configuration = {
      audio = {
        mixer = "software";
        mixer_volume = "";
        #output = "pulsesink";
	#output = "pulsesink device=Snapcast";
        #output = pulsesink server=127.0.0.1
        # output = "audioresample ! audioconvert ! audio/x-raw,rate=48000,channels=2,format=S16LE ! pulsesink  device=kind2  stream-properties="props,media.role=music"
        #output = lamemp3enc ! shout2send mount=mopidy ip=192.168.1.24 port=8000 username=source password=hackme
	output = "audioresample ! audioconvert ! audio/x-raw,rate=48000,channels=2,format=S16LE ! filesink location=/run/pulse/snap-mopidy-fifo";
      };
      mpd = {
        hostname = "${cfg.listenAddress}";
        port = 6600;
      };
      http = {
        hostname = "${cfg.listenAddress}";
        port = 6680;
        zeroconf = mkIf config.services.avahi.enable "Music ${config.services.avahi.hostName}";
      };
      file.enabled = false;
      #logging.verbosity = 4;

      spotify.enabled = false; # TODO define extraConfigFiles=[ "/etc/mopidy/spotify.conf" ];
      # with your username, password, client_id, client_secret
    };

    #sound.enable = true;
    #sound.mediaKeys.enable = true;
    hardware.pulseaudio = {
      enable = true;
      support32Bit = true;
      tcp.enable = true;
      tcp.anonymousClients.allowAll = true;
      tcp.anonymousClients.allowedIpRanges = [ "127.0.0.1" "192.168.1.0/24" ];
      systemWide = true;
      extraConfig = ''
        load-module module-pipe-sink file=/run/pulse/snap-mopidy-fifo sink_name=Snapcast format=s16le rate=48000
        update-sink-proplist Snapcast device.description=Snapcast
      '';
      #load-module module-pipe-sink file=/tmp/wohn.fifo   sink_name=wohn
      #load-module module-pipe-sink file=/tmp/kind1.fifo  sink_name=kind1
      #load-module module-pipe-sink file=/tmp/kind2.fifo  sink_name=kind2
      #load-module module-pipe-sink file=/tmp/kueche.fifo sink_name=kueche

      #load-module module-combine-sink slaves=kind1,kind2 sink_name=kinder
      #load-module module-combine-sink slaves=wohn,kueche sink_name=unten
      #load-module module-combine-sink slaves=wohn,kueche,kind1,kind2 sink_name=alle

      #pactl load-module module-role-ducking trigger_roles=announcement ducking_roles=music
    };

    users.users.root.extraGroups = lib.optionals (config.users.groups ? pulse) [ "pulse" "audio" ];
    users.users.mopidy.extraGroups = lib.optionals (config.users.groups ? pulse) [ "pulse" "audio" "snapserver" ];

    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [
      pkgs.dconf
      pavucontrol
      pamixer
      paprefs
    ];
    # https://blog.pclewis.com/2016/03/20/mopidy-with-extensions-on-nixos.html
    # https://blog.usejournal.com/building-a-personal-aggregated-music-streaming-service-569c9155cedd
    # icecast2
    services.mopidy = {
      enable = true;
      extensionPackages = [
        pkgs.mopidy-mpd
        pkgs.mopidy-spotify
        #pkgs.mopidy-mopify #FIXME blank page
        pkgs.mopidy-iris
        pkgs.mopidy-local
        #pkgs.mopidy-jellyfin
        #pkgs.mopidy-beets
      ];
      configuration = lib.generators.toINI {} cfg.configuration;

      extraConfigFiles = [
        "/etc/mopidy/spotify.conf"
      ];
    };
    networking.firewall.interfaces.bond0.allowedUDPPorts = [
      1900
    ];
    networking.firewall.interfaces.bond0.allowedTCPPorts = [
      1900
      config.role.mopidy-server.configuration.mpd.port
      config.role.mopidy-server.configuration.http.port
      8000 /* stream */
      4317 /* module-native-protocol-tcp will use 4317/tcp port to handle connections */
      #config.services.upmpdcli.configuration.upnpport
      #(config.services.upmpdcli.configuration.upnpport + 1)
      #9090
    ];

    services.snapserver.enable = true;
    services.snapserver.streams.snapinfo = {
      type = "pipe";
      location = "/run/snapserver/snapfifo";
      query = {
        sampleformat="48000:16:2";
        codec="flac";
        mode="create";
      };
    };
    services.snapserver.streams.mopidy = {
      type = "pipe";
      location = "/run/pulse/snap-mopidy-fifo";
      query.mode = "read";
      query.sampleformat="48000:16:2";
    };
    #services.snapserver.streams.spotify-connect = {
    #  type = "spotify";
    #  location = "/${pkgs.librespot}/bin/librespot";
    #  query = {
    #    name = "Spotify";
    #    username = "";
    #    password = "";
    #    #onstart = "";
    #    #onstop = "";
    #  };
    #};

    # Publish this server and its address on the network
    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
      };
      interfaces = [ "lo" "bond0" ];
      #extraServiceFiles = {
      #  ssh = "''${pkgs.avahi}/etc/avahi/services/ssh.service";
      #};
      nssmdns = true;
    };

    services.upmpdcli.enable = true;
    services.upmpdcli.configuration = {
      upnpip = "${cfg.listenAddress}";
      mpdhost = "${cfg.listenAddress}";
      upnpport = 49152;
      friendlyname = "UpMpd ${config.services.avahi.hostName}";
      #uprcluser = "enable"; # Bogus user name variable. Used for consistency with other Media Server plugins to decide if the service should be started (so, do set it if you want a Media Server).
      #uprcltitle = "UpMpd ${config.services.avahi.hostName} server";
      #uprclhostport = "${cfg.listenAddress}:9090";
      #uprclmediadirs = mkIf (cfg.configuration.local?media_dir) cfg.configuration.local.media_dir;
    };

    # output = lamemp3enc ! shout2send mount=/mopidy ip=192.168.1.24 port=8000 username=source password=hackme
    # Source (/mopidy) attempted to login with invalid or missing password
    services.icecast.enable = false;
    services.icecast.hostname = "mopidy";
    services.icecast.admin.user = "mopidy";
    services.icecast.admin.password = "hackme";
    services.icecast.listen.address = "192.168.1.24";
    services.icecast.extraConf = ''
      <burst-on-connect>0</burst-on-connect>
      <mount>
        <mount-name>/mopidy</mount-name>
        <fallback-mount>/silence.mp3</fallback-mount>
        <fallback-override>1</fallback-override>
        <username>source</username>
        <password>hackme</password>
      </mount>

      <authentication>
        <source-password>hackme</source-password>
      </authentication>

      <paths>
        <webroot>${webroot}</webroot>
      </paths>

      <logging>
          <loglevel>4</loglevel> <!-- 4 Debug, 3 Info, 2 Warn, 1 Error -->
      </logging>
    '';
  };
}
