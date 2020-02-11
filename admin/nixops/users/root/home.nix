# https://rycee.net/posts/2017-07-02-manage-your-home-with-nix.html
{ system ? builtins.currentSystem, overlays ? [] }:
let
  homes = {
    home = { pkgs, lib
           , ...}:
           with lib;
    {
      home.username = lib.mkForce "root";
      home.homeDirectory = lib.mkForce "/root";

      nixpkgs.system = system;
      nixpkgs.pkgs = import <nixpkgs> {
        config = import <nur_dguibert/config.nix>;
        inherit system;
      };
      nixpkgs.overlays = [
        ( import <nur_dguibert/overlays>).default
      ] ++ overlays;
      programs.bash.shellAliases.ls="ls --color";

      programs.bash.initExtra = ''
        # Provide a nice prompt.
        PS1=""
        PS1+='\[\033[01;37m\]$(exit=$?; if [[ $exit == 0 ]]; then echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗ $exit"; fi)'
        PS1+='$(ip netns identify 2>/dev/null)' # sudo setfacl -m u:$USER:rx /var/run/netns
        PS1+=' ''${GIT_DIR:+ \[\033[00;32m\][$(basename $GIT_DIR)]}'
        PS1+=' ''${ENVRC:+ \[\033[00;33m\]env:$ENVRC}'
        PS1+=' ''${SLURM_NODELIST:+ \[\033[01;34m\][$SLURM_NODELIST]\[\033[00m\]}'
        PS1+=' \[\033[00;31m\]\u@\h\[\033[01;34m\] \W '
        if ! command -v __git_ps1 >/dev/null; then
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
          ;;
        esac

        eval "$(${pkgs.coreutils}/bin/dircolors)"
      '';

      programs.direnv.enable = true;

      programs.bash.enable = true;
      programs.bash.historySize = 50000;
      programs.bash.historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      programs.bash.historyIgnore = [ "ls" "cd" "clear" "[bf]g" ];

      home.sessionVariables.PROMPT_COMMAND="history -a; history -c; history -r";
      home.sessionVariables.EDITOR="vim";
      home.sessionVariables.GIT_PS1_SHOWDIRTYSTATE=1;

      home.packages = with pkgs; [
        (vim_configurable.override {
          guiSupport = "no";
          gtk2=null; gtk3=null;
          libX11=null; libXext=null; libSM=null; libXpm=null; libXt=null; libXaw=null; libXau=null; libXmu=null;
          libICE=null;
        })
        editorconfig-core-c
      ];
      home.file.".inputrc".text = ''
        set show-all-if-ambiguous on
        set visible-stats on
        set page-completions off
        # http://www.caliban.org/bash/
        #set editing-mode vi
        #set keymap vi
        set show-all-if-ambiguous on
        #Control-o: ">&sortie"
        "\e[A": history-search-backward
        "\e[B": history-search-forward

        "\e[1~": beginning-of-line
        "\e[4~": end-of-line
        "\e[7~": beginning-of-line
        "\e[8~": end-of-line
        "\eOH": beginning-of-line
        "\eOF": end-of-line
        "\e[H": beginning-of-line
        "\e[F": end-of-line
      '';

      # mimeapps.list
      # https://github.com/bobvanderlinden/nix-home/blob/master/home.nix
      home.keyboard.layout = "fr";

    };
  };
in homes
