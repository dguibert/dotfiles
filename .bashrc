# ~/.bashrc: executed by bash(1) for non-login shells.

umask 0027 # group readable, none for others
# User specific environment and startup programs
export PATH=$HOME/bin:$PATH
export MANPATH=$HOME/man:$MANPATH
export EDITOR=vim

# https://sites.google.com/site/ewalker544/research-2/myrt
export PATH=$HOME/bin:$HOME/myrt/bin:$PATH
case $(hostname) in
	manny*|\
	genji*|\
	login*|\
	robin*|\
	pm-mgt0*)
	# PATH specific on clusters
	export PATH=$HOME/pkgs/bin:$PATH
	export PATH=/home_nfs/isv/allinea/forge-6.1.2/bin:$PATH
	export PATH=/home_nfs/isv/allinea/perfreport-6.1.2/bin:$PATH
	;;
esac

#if [ -d ~/code/spack ]; then
#  export PATH=~/code/spack/bin:$PATH
#  . ~/code/spack/share/spack/setup-env.sh
##  export ICCCFG=~/.spack/intel.cfg
##  export ICPCCFG=~/.spack/intel.cfg
##  export IFORTCFG=~/.spack/intel.cfg
#fi

if [ -d ~/pkgs/stowed ]; then
  export PATH=$HOME/pkgs/stowed/bin:$PATH
  export MANPATH=$HOME/pkgs/stowed/share/man:$MANPATH
  export TERMINFO_DIRS=$HOME/pkgs/stowed/share/terminfo:$TERMINFO_DIRS
fi

if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
	source $HOME/.nix-profile/etc/profile.d/nix.sh
fi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

#eval `dircolors`
eval $(TERM=xterm-256color dircolors)
alias ls='ls --color'
# User specific aliases and functions
if command -v hub >/dev/null; then
	alias git=hub
fi

#eval `keychain --noask -q --eval id_dsa david.guibert`

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

export GIT_PS1_SHOWDIRTYSTATE=1
# Provide a nice prompt.
PS1=""
PS1+='\[\033[01;37m\]$(exit=$?; if [[ $exit == 0 ]]; then echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗ $exit"; fi)'
PS1+='$(ip netns identify 2>/dev/null)' # sudo setfacl -m u:$USER:rx /var/run/netns
PS1+='${GIT_DIR:+ \[\033[00;32m\][$(basename $GIT_DIR)]}'
PS1+='${ENVRC:+ \[\033[00;33m\]env:$ENVRC}'
PS1+='${SLURM_NODELIST:+ \[\033[01;34m\][$SLURM_NODELIST]\[\033[00m\]}'
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

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
export HISTIGNORE="ls:cd:clear:[bf]g"
export HISTCONTROL=ignoredups:ignorespace

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=50000
export HISTFILESIZE=100000

# http://ubuntuforums.org/showthread.php?t=1150822
## Save and reload the history after each command finishes
shopt -s histappend
export PROMPT_COMMAND="history -a; history -c; history -r"
#shopt -s histreedit
#shopt -s histverify

#export AWT_TOOLKIT=MToolkit

# man gpg-agent@EXAMPLES
# https://www.unix-ag.uni-kl.de/~guenther/gpg-agent-for-ssh.html
export GPG_TTY=$(tty)
# If you enabled the Ssh Agent Support, you also need to tell ssh about it by adding this to your init script:
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
	export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

if command -v direnv &> /dev/null; then
  eval "$(direnv hook bash)"
fi
export SQUEUE_FORMAT="%.18i %.25P %.8j %.8u %.2t %.10M %.6D %.6C %.6z %.15E %20R %W"
#export SINFO_FORMAT="%30N  %.6D %.6c %15F %10t %20f %P" # with state
export SINFO_FORMAT="%30N  %.6D %.6c %15F %20f %P"
