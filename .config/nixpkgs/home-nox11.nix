# https://rycee.net/posts/2017-07-02-manage-your-home-with-nix.html
{ pkgs, lib, ...}:
with lib;
{
  programs.home-manager.enable = true;

  programs.bash.enable = true;
  programs.bash.historySize = 50000;
  programs.bash.historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
  programs.bash.historyIgnore = [ "ls" "cd" "clear" "[bf]g" ];

  programs.bash.shellAliases.ls="ls --color";

  programs.bash.initExtra = ''
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
PS1+='$(__git_ps1 "|%s|")'
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

  programs.git.enable = true;
  programs.git.package = pkgs.git;
  programs.git.userName = "David Guibert";
  programs.git.userEmail = "david.guibert@gmail.com";
  programs.git.aliases.files = 	"ls-files -v --deleted --modified --others --directory --no-empty-directory --exclude-standard";
  programs.git.aliases.wdiff = "diff --word-diff=color --unified=1";
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

  # http://ubuntuforums.org/showthread.php?t=1150822
  ## Save and reload the history after each command finishes
  home.sessionVariables.PROMPT_COMMAND="history -a; history -c; history -r";
  home.sessionVariables.SQUEUE_FORMAT="%.18i %.25P %35j %.8u %.2t %.10M %.6D %.6C %.6z %.15E %20R %W";
 #home.sessionVariables.SINFO_FORMAT="%30N  %.6D %.6c %15F %10t %20f %P"; # with state
  home.sessionVariables.SINFO_FORMAT="%30N  %.6D %.6c %15F %20f %P";
  home.sessionVariables.PATH="$HOME/bin:$PATH";
  home.sessionVariables.MANPATH="$HOME/man:$MANPATH";
  home.sessionVariables.EDITOR="vim";
  home.sessionVariables.GIT_PS1_SHOWDIRTYSTATE=1;
  # ✗ 1    dguibert@vbox-57nvj72 ~ $ systemctl --user status
  # Failed to read server status: Process org.freedesktop.systemd1 exited with status 1
  # ✗ 130    dguibert@vbox-57nvj72 ~ $ export XDG_RUNTIME_DIR=/run/user/$(id -u)
  home.sessionVariables.XDG_RUNTIME_DIR="/run/user/$(id -u)";


  # Fix stupid java applications like android studio
  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";

  home.packages = with pkgs; [
    vim_configurable
    editorconfig-core-c

    #previousPkgs_pu.gitAndTools.git-annex
    #mr

    #git
    gitAndTools.gitRemoteGcrypt
    gitAndTools.git-crypt

    direnv
    dvtm

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
    gnupg1compat
    #wpsoffice
    file
    (pass.withExtensions (extensions: with extensions; [ pass-audit pass-update ]))
    git-credential-password-store
    bc
  ];

  services.gpg-agent.enable = true;
  services.gpg-agent.enableSshSupport = true;

  xresources.properties = {
    "*visualBell" = false;
    "*urgentOnBell" = true;
    "*font" = "-*-terminus-medium-*-*-*-14-*-*-*-*-*-iso10646-1";
    "*saveLines" = 50000;
    "Rxvt.scrollBar" = false;
    "Rxvt.scrollTtyOutput" = false;
    "Rxvt.scrollTtyKeypress" = true;
    "Rxvt.scrollWithBuffer" = false;
    "Rxvt.jumpScroll" = true;
    "*loginShell" = true;

    "URxvt.searchable-scrollback" = "CM-s";
    "URxvt.utf8" = true;

    "URxvt.transparent" = false;
    "URxvt.depth" = 32;
    "URxvt.intensityStyles" = false;
    "URxvt.termName" = "xterm-256color";
  };
  xresources.extraConfig = builtins.readFile (
      pkgs.fetchFromGitHub {
          owner = "solarized";
          repo = "xresources";
          rev = "refs/heads/master";
          sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
      } + "/Xresources.light"
  );

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

  fonts.fontconfig.enableProfileFonts = true;

  # mimeapps.list
  # https://github.com/bobvanderlinden/nix-home/blob/master/home.nix
  home.keyboard.layout = "fr";
}
