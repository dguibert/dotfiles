{ ... }:
{
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


}
