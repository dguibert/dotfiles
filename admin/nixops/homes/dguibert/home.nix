{ config
, pkgs
, lib
, inputs
, outputs
, sopsDecrypt_
, ...
}@args:
with lib;
let
  home-secret =
    let
      home_sec = sopsDecrypt_ ./home-sec.nix "data";
      loaded = home_sec.success or true;
    in
    if loaded
    then (builtins.trace "loaded encrypted ./homes/dguibert/home-sec.nix (${toString loaded})" home_sec)
    else
      (builtins.trace "use dummy        ./homes/dguibert/home-sec.nix (${toString loaded})"
        ({ ... }: { }));

  davmail_ = pkgs.davmail.override { jre = pkgs.oraclejre; };
in
{
  imports = [
    # import the base16.nix module
    inputs.base16.nixosModule
    # set system's scheme to nord by setting `config.scheme`
    { scheme = "${inputs.base16-schemes}/solarized-dark.yaml"; }

    outputs.homeManagerModules.report-changes
    ({ ... }: { home.report-changes.enable = true; })
    ({ ... }: {
      options.centralMailHost.enable = mkEnableOption "Host running liier/mbsync";
      config.centralMailHost.enable = lib.mkDefault false;
    })
    ({ ... }: {
      options.withGui.enable = mkEnableOption "Host running with X11 or Wayland";
      config.withGui.enable = lib.mkDefault false;
    })
    ({ ... }: { manual.manpages.enable = false; })

    home-secret

    ./module-dwl.nix
    ./with-gui.nix
  ];
  services.gpg-agent.pinentryFlavor = lib.mkForce "curses";

  programs.home-manager.enable = true;

  nixpkgs.config = pkgs: (import "${inputs.nur_dguibert}/config.nix" pkgs) // {
    # https://nixos.wiki/wiki/Chromium
    chromium.commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
  };

  nixpkgs.overlays = [
    inputs.nix.overlays.default
    inputs.emacs-overlay.overlay
    #inputs.nixpkgs-wayland.overlay
    inputs.nur.overlay
    inputs.nur_dguibert.overlay
    inputs.nur_dguibert.overlays.extra-builtins
    inputs.nur_dguibert.overlays.emacs
    #nur_dguibert_envs.overlay
    inputs.nxsession.overlay
    inputs.self.overlays.default
  ];

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
    "man"
    "man *"
    "pwd"
    "exit"
    "date"
    "* --help:"
  ];

  programs.bash.shellAliases.ls = "ls --color";

  programs.bash.bashrcExtra = ''
    if [[ -z $WAYLAND_DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && command -v dwl-session >/dev/null ; then
      exec dwl-session
    fi
  '';
  programs.bash.initExtra = ''
    export HISTCONTROL
    export HISTFILESIZE
    export HISTIGNORE
    export HISTSIZE
    # https://unix.stackexchange.com/a/430128
    # on every prompt, save new history to dedicated file and recreate full history
    # by reading all files, always keeping history from current session on top.
    update_history () {
      history -a ''${HISTFILE}.$$
      history -c
      history -r  # load common history file
      # load histories of other sessions
      for f in `ls ''${HISTFILE}.[0-9]* 2>/dev/null | grep -v "''${HISTFILE}.$$\$"`; do
        history -r $f
      done
      history -r "''${HISTFILE}.$$"  # load current session history
    }
    if [[ "$PROMPT_COMMAND" != *update_history* ]]; then
      export PROMPT_COMMAND="update_history''${PROMPT_COMMAND:+;$PROMPT_COMMAND }"
    fi

    # merge session history into main history file on bash exit
    merge_session_history () {
      if [ -e ''${HISTFILE}.$$ ]; then
        # fix wrong history files
        awk '/^[0-9]+ / { gsub("^[0-9]+ +", "") } { print }' $HISTFILE ''${HISTFILE}.$$ | \
        tac | awk '!seen[$0]++' | tac | ${pkgs.moreutils}/bin/sponge  $HISTFILE
        \rm ''${HISTFILE}.$$
      fi
    }
    trap merge_session_history EXIT

    # detect leftover files from crashed sessions and merge them back
    active_shells=$(pgrep `ps -p $$ -o comm=`)
    grep_pattern=`for pid in $active_shells; do echo -n "-e \.''${pid}\$ "; done`
    orphaned_files=`ls $HISTFILE.[0-9]* 2>/dev/null | grep -v $grep_pattern`

    if [ -n "$orphaned_files" ]; then
      echo Merging orphaned history files:
      for f in $orphaned_files; do
        echo "  `basename $f`"
        cat $f >> $HISTFILE
        \rm $f
      done
      tac $HISTFILE | awk '!seen[$0]++' | tac | ${pkgs.moreutils}/bin/sponge $HISTFILE
      echo "done."
    fi
    # https://www.gnu.org/software/emacs/manual/html_node/tramp/Remote-shell-setup.html#index-TERM_002c-environment-variable-1
    test "$TERM" != "dumb" || return

    # https://codeberg.org/dnkl/foot/issues/86
    # https://codeberg.org/dnkl/foot/wiki#user-content-how-to-configure-my-shell-to-emit-the-osc-7-escape-sequence
    _urlencode() {
            local length="''${#1}"
            for (( i = 0; i < length; i++ )); do
                    local c="''${1:$i:1}"
                    case $c in
                            %) printf '%%%02X' "'$c" ;;
                            *) printf "%s" "$c" ;;
                    esac
            done
    }
    osc7_cwd() {
            printf '\e]7;file://%s%s\a' "$HOSTNAME" "$(_urlencode "$PWD")"
    }
    PROMPT_COMMAND=''${PROMPT_COMMAND:+$PROMPT_COMMAND; }osc7_cwd

    # Provide a nice prompt.
    PS1=""
    PS1+='\[\033[01;37m\]$(exit=$?; if [[ $exit == 0 ]]; then echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗ $exit"; fi)'
    PS1+='$(ip netns identify 2>/dev/null)' # sudo setfacl -m u:$USER:rx /var/run/netns
    PS1+=' ''${GIT_DIR:+ \[\033[00;32m\][$(basename $GIT_DIR)]}'
    PS1+=' ''${ENVRC:+ \[\033[00;33m\]env:$ENVRC}'
    PS1+=' ''${SLURM_NODELIST:+ \[\033[01;34m\][$SLURM_NODELIST]\[\033[00m\]}'
    PS1+=' \[\033[00;32m\]\u@\h\[\033[01;34m\] \W '
    if !  command -v __git_ps1 >/dev/null; then
      if [ -e $HOME/code/git-prompt.sh ]; then
        source $HOME/code/git-prompt.sh
      fi
    fi
    if command -v __git_ps1 >/dev/null; then
      PS1+='$(__git_ps1 "|%s|")'
    fi
    PS1+='$\[\033[00m\] '

    export PS1
    case $TERM in
      dvtm*|st*|rxvt|*term)
        trap 'echo -ne "\e]0;$BASH_COMMAND\007"' DEBUG
        PS1+='\[\033]0;\u@\h: \w\007\]'
      ;;
    esac

    eval "$(${pkgs.coreutils}/bin/dircolors)"
    source ${config.scheme inputs.base16-shell}

    export TODOTXT_DEFAULT_ACTION=ls
    alias t='todo.sh'

    tput smkx
  '';

  #home.file.".vim/base16.vim".source = ./base16.vim;
  home.file.".vim/base16.vim".source = config.scheme inputs.base16-vim;

  programs.git.enable = true;
  programs.git.package = pkgs.gitFull;
  programs.git.userName = "David Guibert";
  programs.git.userEmail = "david.guibert@gmail.com";
  programs.git.aliases.files = "ls-files -v --deleted --modified --others --directory --no-empty-directory --exclude-standard";
  programs.git.aliases.wdiff = "diff --word-diff=color --unified=1";
  programs.git.aliases.bd = "!git for-each-ref --sort='-committerdate:iso8601' --format='%(committerdate:iso8601)%09%(refname)'";
  programs.git.aliases.bdr = "!git for-each-ref --sort='-committerdate:iso8601' --format='%(committerdate:iso8601)%09%(refname)' refs/remotes/$1";
  programs.git.aliases.bs = "branch -v -v";
  programs.git.aliases.df = "diff";
  programs.git.aliases.dn = "diff --name-only";
  programs.git.aliases.dp = "diff --no-ext-diff";
  programs.git.aliases.ds = "diff --stat -w";
  programs.git.aliases.dt = "difftool";
  #programs.git.ignores
  programs.git.iniContent.clean.requireForce = true;
  programs.git.iniContent.rerere.enabled = true;
  programs.git.iniContent.rerere.autoupdate = true;
  programs.git.iniContent.rebase.autosquash = true;
  programs.git.iniContent.credential.helper = "password-store";
  programs.git.iniContent."url \"software.ecmwf.int\"".insteadOf = "ssh://git@software.ecmwf.int:7999";
  programs.git.iniContent.color.branch = "auto";
  programs.git.iniContent.color.diff = "auto";
  programs.git.iniContent.color.interactive = "auto";
  programs.git.iniContent.color.status = "auto";
  programs.git.iniContent.color.ui = "auto";
  programs.git.iniContent.diff.tool = "vimdiff";
  programs.git.iniContent.diff.renames = "copies";
  programs.git.iniContent.merge.tool = "vimdiff";
  programs.git.iniContent.pull.ff = "only"; # fast-forward only
  programs.git.extraConfig.safe.directory = "/home/dguibert/sshfs/spartan/work/hpcw";

  # http://ubuntuforums.org/showthread.php?t=1150822
  ## Save and reload the history after each command finishes
  home.sessionVariables.SQUEUE_FORMAT = "%.18i %.25P %35j %.8u %.2t %.10M %.6D %.6C %.6z %.15E %20R %W";
  #home.sessionVariables.SINFO_FORMAT="%30N  %.6D %.6c %15F %10t %20f %P"; # with state
  home.sessionVariables.SINFO_FORMAT = "%30N  %.6D %.6c %15F %20f %P";
  home.sessionVariables.PATH = "$HOME/bin:$PATH";
  home.sessionVariables.MANPATH = "$HOME/man:$MANPATH:/share/man:/usr/share/man";
  home.sessionVariables.PAGER = "less -R";
  home.sessionVariables.LESS = "RFX";
  home.sessionVariables.GIT_PS1_SHOWDIRTYSTATE = 1;
  # ✗ 1    dguibert@vbox-57nvj72 ~ $ systemctl --user status
  # Failed to read server status: Process org.freedesktop.systemd1 exited with status 1
  # ✗ 130    dguibert@vbox-57nvj72 ~ $ export XDG_RUNTIME_DIR=/run/user/$(id -u)
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$(id -u)";
  home.sessionVariables.MOZ_ENABLE_WAYLAND = 1;

  # Fix stupid java applications like android studio
  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";

  home.packages = with pkgs; [
    (vim_configurable.override {
      guiSupport = "no";
      libX11 = null;
      libXext = null;
      libSM = null;
      libXpm = null;
      libXt = null;
      libXaw = null;
      libXau = null;
      libXmu = null;
      libICE = null;
    })

    rsync

    gitAndTools.git-remote-gcrypt
    gitAndTools.git-crypt

    gnumake
    #nix-repl
    pstree

    screen
    #teamviewer
    tig
    lsof
    #haskellPackages.nix-deploy
    htop
    tree

    #wpsoffice
    file
    bc
    unzip

    sshfs-fuse

    moreutils
    jq
  ] ++ optionals config.withGui.enable [
    pandoc

    (pass.withExtensions (extensions: with extensions; [ pass-audit pass-update pass-otp pass-import pass-checkup ]))
    gitAndTools.git-credential-password-store

    perlPackages.GitAutofixup

    nix-prefetch-scripts
    nix-update

    mr
    mercurial
    #previousPkgs_pu.gitAndTools.git-annex
    youtube-dl
    gitAndTools.git-annex
    gitAndTools.git-annex-remote-rclone
    (pkgs.writeScriptBin "git-annex-diff-wrapper" ''
      #!${pkgs.runtimeShell}
      LANG=C ${pkgs.diffutils}/bin/diff -u "$1" "$2"
      exit 0
    '')
    bup
    par2cmdline
    fpart # ~/Makefile ~/bin/prepare-bd.sh
    rclone
    datalad

    imagemagick
    exiftool
    udftools
    gitAndTools.hub # command-line wrapper for git that makes you better at GitHub

    dwm
    dmenu
    xlockmore
    xautolock
    xorg.xset
    xorg.xinput
    xorg.xsetroot
    xorg.setxkbmap
    xorg.xmodmap
    rxvt-unicode-unwrapped
    st
    dvtm
    abduco
    pamixer
    xsel
    xclip
    (conky.override { x11Support = false; })
    gnuplot
    mkpasswd
    aria2
    qtpass
    qrencode

    go-mtpfs

    wayland
    corkscrew
    autossh

    urlscan

    hledger
    haskellPackages.hledger-interest
    #pythonPackages.ofxparse
    #pkgs-18_09.pythonPackages.weboob
    python3Packages.woob

    mpv
    python3Packages.subliminal
    python3

    baobab
    #bup
    #par2cmdline

    lieer
    muchsync
    notmuch-addrlookup
    #firefox-bin

    terminus_font
    powerline-fonts #corefonts
    fira-code
    fira-code-symbols

    nxsession

    # my-emacs # 20211026 installed via programs.emacs.package
    my-texlive

    (makeDesktopItem {
      name = "org-protocol";
      exec = "emacsclient %u";
      comment = "Org protocol";
      desktopName = "org-protocol";
      type = "Application";
      mimeTypes = [ "x-scheme-handler/org-protocol" ];
    })
  ] ++ optionals config.centralMailHost.enable [
    davmail_
  ];

  services.gpg-agent.enable = true;
  services.gpg-agent.enableSshSupport = true;
  # https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/
  home.file.".gnupg/gpg.conf".text = ''
    # Avoid information leaked
    no-emit-version
    no-comments
    export-options export-minimal

    # Displays the long format of the ID of the keys and their fingerprints
    keyid-format 0xlong
    with-fingerprint

    # Displays the validity of the keys
    list-options show-uid-validity
    verify-options show-uid-validity

    # Limits the algorithms used
    personal-cipher-preferences AES256
    personal-digest-preferences SHA512
    default-preference-list SHA512 SHA384 SHA256 RIPEMD160 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed

    cipher-algo AES256
    digest-algo SHA512
    cert-digest-algo SHA512
    compress-algo ZLIB

    disable-cipher-algo 3DES
    weak-digest SHA1

    s2k-cipher-algo AES256
    s2k-digest-algo SHA512
    s2k-mode 3
    s2k-count 65011712
  '';


  home.file.".inputrc".text = ''
    set show-all-if-ambiguous on
    set visible-stats on
    set page-completions off
    # https://git.suckless.org/st/file/FAQ.html
    set enable-keypad on
    # http://www.caliban.org/bash/
    #set editing-mode vi
    #set keymap vi
    #Control-o: ">&sortie"
    "\e[A": history-search-backward
    "\e[B": history-search-forward
    "\e[1;5A": history-search-backward
    "\e[1;5B": history-search-forward

    # Arrow keys in keypad mode
    "\C-[OA": history-search-backward
    "\C-[OB": history-search-forward
    "\C-[OC": forward-char
    "\C-[OD": backward-char

    # Arrow keys in ANSI mode
    "\C-[[A": history-search-backward
    "\C-[[B": history-search-forward
    "\C-[[C": forward-char
    "\C-[[D": backward-char

    # mappings for Ctrl-left-arrow and Ctrl-right-arrow for word moving
    "\e[1;5C": forward-word
    "\e[1;5D": backward-word
    #"\e[5C": forward-word
    #"\e[5D": backward-word
    "\e\e[C": forward-word
    "\e\e[D": backward-word

    $if mode=emacs

    # for linux console and RH/Debian xterm
    "\e[1~": beginning-of-line
    "\e[4~": end-of-line
    "\e[5~": beginning-of-history
    "\e[6~": end-of-history
    "\e[7~": beginning-of-line
    "\e[3~": delete-char
    "\e[2~": quoted-insert
    "\e[5C": forward-word
    "\e[5D": backward-word
    "\e\e[C": forward-word
    "\e\e[D": backward-word
    "\e[1;5C": forward-word
    "\e[1;5D": backward-word

    # for rxvt
    "\e[8~": end-of-line

    # for non RH/Debian xterm, can't hurt for RH/DEbian xterm
    "\eOH": beginning-of-line
    "\eOF": end-of-line

    # for freebsd console
    "\e[H": beginning-of-line
    "\e[F": end-of-line
    $endif
  '';

  # mimeapps.list
  # https://github.com/bobvanderlinden/nix-home/blob/master/home.nix
  home.keyboard.layout = "fr";

  #systemd.user.sockets.socks-rpi31 = {
  #  Unit.Description = "Socks tunnel on 33328 via my rpi31";
  #  Socket = {
  #    ListenStream = "127.0.0.1:33328";
  #    Accept=true;
  #  };
  #  Install.WantedBy = [ "sockets.target" ];
  #};
  #systemd.user.services.socks-rpi31 = {
  #  Unit = {
  #    Description = "Socks tunnel on 33328 via my rpi31";
  #    #Requires = "socks-rpi31.socket";
  #    #After = "socks-rpi31.socket";
  #    ## This is a socket-activated service:
  #    #RefuseManualStart = true;
  #  };
  #  Service.ExecStart = "${pkgs.openssh}/bin/ssh -N -D 33328 rpi31";
  #  Service.StandardInput= "socket";
  #};
  programs.tmux.enable = true;
  programs.tmux.sensibleOnTop = false;
  #programs.tmux.secureSocket = false; # https://github.com/NixOS/nixpkgs/pull/62136
  programs.tmux.plugins = with pkgs; [
    tmuxPlugins.copycat
    {
      plugin = tmuxPlugins.pain-control;
      extraConfig = "set-option -g @pane_resize '10'";
    }
    #{
    #  plugin = tmuxPlugins.resurrect;
    #  extraConfig = "set -g @resurrect-strategy-nvim 'session'";
    #}
    #{
    #  plugin = tmuxPlugins.continuum;
    #  extraConfig = ''
    #    set -g @continuum-restore 'on'
    #    set -g @continuum-save-interval '60' # minutes
    #  '';
    #}
  ];
  programs.tmux.extraConfig = ''
    source-file ${config.scheme inputs.base16-tmux}

    set -g prefix C-a
    # ============================================= #
    # Start with defaults from the Sensible plugin  #
    # --------------------------------------------- #
    run-shell ${pkgs.tmuxPlugins.sensible.rtp}
    # ============================================= #
    # new window and retain cwd
    bind c new-window -c "#{pane_current_path}"

    # Prompt to rename window right after it's created
    #set-hook -g after-new-window 'command-prompt -I "#{window_name}" "rename-window '%%'"'

    # Rename session and window
    bind r command-prompt -I "#{window_name}" "rename-window '%%'"
    bind R command-prompt -I "#{session_name}" "rename-session '%%'"

    # =====================================
    # ===        Renew environment      ===
    # =====================================
    set -g update-environment \
      "DISPLAY\
      SSH_CLIENT\
      SSH_ASKPASS\
      SSH_AUTH_SOCK\
      SSH_AGENT_PID\
      SSH_CONNECTION\
      SSH_TTY\
      WINDOWID\
      XAUTHORITY"

    bind '$' run "~/.tmux/renew_env.sh"

    # Enable mouse support
    set -g mouse on

    # Reload tmux configuration
    bind C-r source-file ~/.tmux.conf \; display "Config reloaded"

    # Link window
    bind L command-prompt -p "Link window from (session:window): " "link-window -s %% -a"

    # ==============================================
    # ===   Nesting local and remote sessions     ===
    # ==============================================
    set -g status-position top

    # Session is considered to be remote when we ssh into host
    if-shell 'test -n "$SSH_CLIENT"' \
        'source-file ~/.tmux/tmux.remote.conf'

    # We want to have single prefix key "C-a", usable both for local and remote session
    # we don't want to "C-a" + "a" approach either
    # Idea is to turn off all key bindings and prefix handling on local session,
    # so that all keystrokes are passed to inner/remote session

    # see: toggle on/off all keybindings · Issue #237 · tmux/tmux - https://github.com/tmux/tmux/issues/237
    # TODO: highlighted for nested local session as well
    wg_is_keys_off="#[fg=$color_light,bg=$color_window_off_indicator]#([ $(tmux show-option -qv key-table) = 'off' ] && echo 'OFF')#[default]"
    if-shell 'test -e ~/.tmux/status.conf' 'source-file ~/.tmux/status.conf'

    # Also, change some visual styles when window keys are off
    bind -T root F12  \
        set prefix None \;\
        set key-table off \;\
        if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
        refresh-client -S \;\

    bind -T off F12 \
      set -u prefix \;\
      set -u key-table \;\
      refresh-client -S
  '';
  home.file.".tmux/renew_env.sh".source = ./tmux/renew_env.sh;
  home.file.".tmux/tmux.remote.conf".source = ./tmux/tmux.remote.conf;
  home.file.".tmux/status.conf".source = ./tmux/status.conf;

  # ssh -F ssh_config $host -o PubkeyAuthentication=yes -Nf
  # ssh -F ssh_config $host -O check
  # ssh -F ssh_config $host -O exit
  #
  # ssh -F ssh_config $host -O forward -L ....
  # ssh -F ssh_config $host -O cancel -L ....
  programs.ssh =
    let
      matchexec_host = host: ip: port: {
        inherit host port;
        exec = "nc -w 1 -z ${ip} ${toString port} 1>&2 >/dev/null";
        hostname = ip;
        proxyCommand = "none";
        extraOptions.HostKeyAlias = host;
      };
      ## https://superuser.com/a/1635657
      home_host = host: ip: port: vpn_ip: mac: {
        ## Coming from localhost.
        "${host}_0" = {
          matchHeader = "originalhost ${host} exec \"[ %h = %L ]\"";
          extraOptions.LocalCommand = "echo \"SSH %n: To localhost\" >&2";
          host = "${host}";
        };
        ## Coming from outside home network.
        "${host}_1" = lib.hm.dag.entryAfter [ "${host}_0" ] {
          host = "${host}";
          matchHeader = "originalhost ${host} !exec \"[ %h = %L ]\" !exec \"{ ip neigh; ip link; }|grep -Fw ${mac}\" !exec \"ip route | grep ${vpn_ip}\"";
          extraOptions.LocalCommand = "echo \"SSH %n: From outside network, to %h\" >&2";
          proxyJump = lib.mkIf (host != "rpi31") "rpi31";
          hostname = lib.mkIf (host == "rpi31") "82.64.121.168";
          port = lib.mkIf (host == "rpi31") 443;

        };
        ## Coming from VPN
        "${host}_2" = lib.hm.dag.entryAfter [ "${host}_1" ] {
          host = "${host}";
          matchHeader = "originalhost ${host} !exec \"[ %h = %L ]\" !exec \"{ ip neigh; ip link; }|grep -Fw ${mac}\" exec \"ip route | grep ${vpn_ip}\"";
          extraOptions.PermitLocalCommand = "yes";
          extraOptions.LocalCommand = "echo \"SSH %n: From VPN network, to %h\" >&2";
          proxyCommand = "none";
          hostname = "${vpn_ip}";
          inherit port;
        };
        ## Coming from inside home network.
        "${host}_3" = lib.hm.dag.entryAfter [ "${host}_2" ] {
          host = "${host}";
          extraOptions.PermitLocalCommand = "yes";
          extraOptions.LocalCommand = "echo \"SSH %n: From home network, to %h\" >&2";
          hostname = "${ip}";
          inherit port;
        };
      };
    in
    {
      enable = true;
      compression = true;
      controlMaster = "auto";
      controlPath = "~/.ssh/socket-%C";
      controlPersist = "4h";

      #extraOptionOverrides = ''
      #'';
      extraConfig = ''
        IdentitiesOnly yes
        #IdentityFile id_dsa
        PasswordAuthentication no
        PubkeyAuthentication yes
        TCPKeepAlive yes
        SendEnv COLORTERM
      '';

      matchBlocks = {
        "*" = {
          exec = "test -e ~/.ssh/extra_config";
          extraOptions.Include = "~/.ssh/extra_config";
        };
        "127.0.0.1 | localhost" = {
          forwardAgent = true;
          forwardX11 = true;
          forwardX11Trusted = true;
          extraOptions.NoHostAuthenticationForLocalhost = "yes";
        };

      }
      // (home_host "rpi31" "192.168.1.13" 22322 "10.147.27.13" "b8:27:eb:46:86:14")
      // (home_host "rpi41" "192.168.1.14" 22322 "10.147.27.14" "dc:a6:32:67:dd:9f")
      // (home_host "t580" "192.168.1.17" 22 "10.147.27.17" "d2:b6:17:1d:b8:97")
      // (home_host "titan" "192.168.1.24" 22 "10.147.27.24" "be:f8:2c:e5:1d:4e")
      ;
    };

  programs.htop.enable = true;
  # fields=0 48 17 18 38 39 40 2 46 47 49 109 110 1
  programs.htop.settings = {
    fields = with config.lib.htop.fields; [
      PID #= 0; #
      USER #= 48; #
      PRIORITY #= 17; #
      NICE #= 18; #
      M_SIZE #= 38; #
      M_RESIDENT #= 39; #
      M_SHARE #= 40; #
      STATE #= 2; #
      PERCENT_CPU #= 46; #
      PERCENT_MEM #= 47; #
      TIME #= 49; #
      IO_READ_RATE #= 109; #
      IO_WRITE_RATE #= 110; #
      COMM
    ];
    hide_threads = true;
    hide_userland_threads = true;
    tree_view = true;
    header_margin = false;
    cpu_count_from_zero = true;
    show_cpu_usage = true;
    color_scheme = 6;
  } // (with config.lib.htop; leftMeters [
    (bar "CPU")
    (bar "Memory")
    (bar "Swap")
  ]) // (with config.lib.htop; rightMeters [
    (text "Tasks")
    (text "LoadAverage")
    (text "Uptime")
  ]);

  home.file.".conkyrc".text = ''
    conky.config = {
        out_to_console = true,
    };
    conky.text = [[
    ''${loadavg 1} \
    ''${cpu cpu0}% ''${freq_g 0}GHz \
    ''${if_existing /sys/class/power_supply/BAT0/present}Bat ''${battery_percent BAT0}% (''${battery_time BAT0})''${else}\
    ''${if_existing /sys/class/power_supply/BAT1/present}Bat ''${battery_percent BAT1}% (''${battery_time BAT1})''${else}AC''${endif}''${endif} \
    ''${if_up bond0}''${upspeedf bond0}k ''${downspeedf bond0}k ''${endif}\
    ''${if_up enp0s3}''${upspeedf enp0s3}k ''${downspeedf enp0s3}k ''${endif}\
    ''${if_up wlp0s26f7u1}''${upspeedf wlp0s26f7u1}k ''${downspeedf wlp0s26f7u1}k ''${endif}\
    ''${time %H:%M}\
    ]]
  '';

}
