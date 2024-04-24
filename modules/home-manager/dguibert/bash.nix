{ lib, config, pkgs, inputs, ... }:
{
  options.withBash.enable = (lib.mkEnableOption "Enable bash config") // { default = true; };
  options.withBash.history-merge = (lib.mkEnableOption "Enable bash history merging") // { default = true; };

  config = lib.mkIf config.withBash.enable {
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

    programs.bash.shellAliases.ls = "ls --color";

    home.sessionVariables.PATH = "$HOME/bin:$PATH";
    home.sessionVariables.MANPATH = "$HOME/man:$MANPATH:/share/man:/usr/share/man";
    home.sessionVariables.PAGER = "less -R";
    home.sessionVariables.LESS = "RFX";
    home.sessionVariables.GIT_PS1_SHOWDIRTYSTATE = 1;

    programs.bash.initExtra = ''
      # pruge previously defined PROMPT_COMMAND
      export PROMPT_COMMAND=

      export HISTCONTROL
      export HISTFILESIZE
      export HISTIGNORE
      export HISTSIZE
      unset HISTTIMEFORMAT
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

    '' +
    (if config.withBash.history-merge then ''
      # merge session history into main history file on bash exit
      merge_session_history () {
      command -v awk &>/dev/null || exit 0
      command -v tac &>/dev/null || exit 0
      if [ -e ''${HISTFILE}.$$ ]; then
          # fix wrong history files
          awk '/^#[0-9]/ { next } /^[0-9]+ / { gsub("^[0-9]+ +", "") } { print }' $HISTFILE ''${HISTFILE}.$$ | \
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
      command -v awk &>/dev/null || exit 0
      command -v tac &>/dev/null || exit 0
      for f in $orphaned_files; do
          echo "  `basename $f`"
          awk '/^#[0-9]/ { next } /^[0-9]+ / { gsub("^[0-9]+ +", "") } { print }' $HISTFILE $f | \
          tac | awk '!seen[$0]++' | tac | ${pkgs.moreutils}/bin/sponge  $HISTFILE
          \rm -f $f
      done
      tac $HISTFILE | awk '!seen[$0]++' | tac | ${pkgs.moreutils}/bin/sponge $HISTFILE
      echo "done."
      fi
    '' else "") + ''
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
      #osc7_cwd() {
      #        printf '\e]7;file://%s%s\a' "$HOSTNAME" "$(_urlencode "$PWD")"
      #}
      #PROMPT_COMMAND=''${PROMPT_COMMAND:+$PROMPT_COMMAND; }osc7_cwd
      # https://gist.github.com/petersenna/442f5f2ab97af65f24c0
      BACK_FILE=''${HISTFILE_BACK:-~/.bash_history_backup}
      save_history() {
      if [ ! -f $BACK_FILE ];then touch -d "2 hours ago" $BACK_FILE;fi
      if test $(find $BACK_FILE -mmin +5); then
              #HIST_SIZE=$(cat $HIST_FILE|wc -l)
              HIST_SIZE=$(history|wc -l)
              BACK_SIZE=$(cat $BACK_FILE|wc -l)
              GROWTH=$(($HIST_SIZE - $BACK_SIZE))

              if [ $GROWTH -lt 0 ];then
                      echo Looks like your bash history has problems...
                      echo You can restore with cp $BACK_FILE $HISTFILE
              else
                      cp $HISTFILE $BACK_FILE
              fi
      fi
      }
      PROMPT_COMMAND=''${PROMPT_COMMAND:+$PROMPT_COMMAND; }save_history

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
      export TODOTXT_DEFAULT_ACTION=ls
      alias t='todo.sh'

      tput smkx
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

  };
}
