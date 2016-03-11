# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

export EDITOR=vim
export PATH=$HOME/.bin:$PATH:$HOME/.nix-profile/bin
export MANPATH=$HOME/man:$MANPATH
export VARDIR=$HOME/.var

if [ -f "${HOME}/.gpg-agent-info" ]; then
  source "${HOME}/.gpg-agent-info"
  export GPG_AGENT_INFO
  export SSH_AUTH_SOCK
fi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

#eval `keychain --noask -q --eval id_dsa david.guibert`
source /home/dguibert/code/git/contrib/completion/git-prompt.sh

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=10000
export HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

export GIT_PS1_SHOWDIRTYSTATE=1
# Provide a nice prompt.
VCSH_PS1="${GIT_DIR:+vcsh:$(basename $GIT_DIR)}"
alias ls='ls --color'
#PS1='$EXIT_CODE\[\033[$PROMPT_COLOR\]$ENV_NAME+\h:$ZPWD$(__git_ps1 "|%s|")\$\[\033[0m\] '
#PS1='$?$ENV_NAME\[\e[0;32m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
#PS1='$?$ENV_NAME\[\e[0;32m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\[\e[m\]$(__git_ps1 "|%s|")\$\[\033[0m\] '
export PS1='\[\033[ 01;37m\]$(exit=$?; if [[ $exit == 0 ]]; then echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗ $exit"; fi)$ENV_NAME$VCSH_PS1 \[\033[00;32m\]\u@\h\[\033[01;34m\] \W $(__git_ps1 "|%s|")\$\[\033[00m\] '
case $TERM in
	rxvt|*term)
#		set -o functrace
		trap 'echo -ne "\e]0;$BASH_COMMAND\007"' DEBUG
#		PS1="\e]0;\h \w\007$PS1"
	;;
esac

eval `dircolors`

#share history with all bash instances
export HISTIGNORE="ls:cd:clear:[bf]g"
export HISTCONTROL=ignoreboth:erasedups     # no duplicate entries
export HISTSIZE=100000           # big big history
export HISTFILESIZE=100000       # big big history
# http://ubuntuforums.org/showthread.php?t=1150822
## Save and reload the history after each command finishes
PROMPT_COMMAND="                history -a"
PROMPT_COMMAND="$PROMPT_COMMAND;history -c"
PROMPT_COMMAND="$PROMPT_COMMAND;history -r"
PROMPT_COMMAND="$PROMPT_COMMAND;history -w"
PROMPT_COMMAND="$PROMPT_COMMAND;history -c"
PROMPT_COMMAND="$PROMPT_COMMAND;history -r"
export PROMPT_COMMAND
shopt -s histreedit
shopt -s histverify
export HISTFILE=$HOME/.bash_history.$(hostname)

#export AWT_TOOLKIT=MToolkit

export PATH=$HOME/bin:$PATH
export GTK_PATH=$GTK_PATH:~/.nix-profile/lib/gtk-2.0
export GTK2_RC_FILES=$GTK2_RC_FILES:~/.nix-profile/share/themes/oxygen-gtk/gtk-2.0/gtkrc
export PYTHONPATH=$HOME/.nix-profile/lib/python2.7/site-packages:/run/current-system/sw/lib/python2.7/site-packages:$PYTHONPATH

function sshtmp () {
	ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" "$@"
}

function sshnew () {
	ssh -o "StrictHostKeyChecking no" "$@"
}

eval "$(direnv hook bash)"
