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
PROMPT_COLOR="1;31m"
let $UID && PROMPT_COLOR="1;32m"
# This function is run at every prompt update, keeping our variables updated.
# Bash's PROMPT_COMMAND option handles this (see end of this function).
RED='\e[0;31m'
ESC='\e[0m'
pre_prompt() {
	# show exit code of last failed command
	local zexit="${?}"
	if [ "$zexit" = "0" ]; then
	        EXIT_CODE=""
        else
		EXIT_CODE="$(echo -ne "$RED$zexit$ESC ")"
	fi

	ZPWD=${PWD/#$HOME/\~}  # sorten home dir to ~

	local pathsize
	let pathsize=${#ZPWD}
	# determine how much to truncate ZPWD
	if [ "$pathsize" -gt "20" ]; then
		ZPWD="…${ZPWD:(-20)}"
	fi
}
PROMPT_COMMAND=:
#pre_prompt

VCSH_PS1="${GIT_DIR:+vcsh:$(basename $GIT_DIR)}"
alias ls='ls --color'
#PS1='$EXIT_CODE\[\033[$PROMPT_COLOR\]$ENV_NAME+\h:$ZPWD$(__git_ps1 "|%s|")\$\[\033[0m\] '
#PROMPT_COMMAND='es=$?; [[ $es -eq 0 ]] && unset error || error=$(echo -e "\e[1;41m $es \e[0;40m")'
#PS1='$?$ENV_NAME\[\e[0;32m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
#PS1='$?$ENV_NAME\[\e[0;32m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\[\e[m\]$(__git_ps1 "|%s|")\$\[\033[0m\] '
PS1='\[\033[ 01;37m\]$(exit=$?; if [[ $exit == 0 ]]; then echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗ $exit"; fi)$ENV_NAME$VCSH_PS1 \[\033[00;32m\]\u@\h\[\033[01;34m\] \W $(__git_ps1 "|%s|")\$\[\033[00m\] '
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
PROMPT_COMMAND="$PROMPT_COMMAND;history -a"
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

export AUTOSSH_GATETIME=0
export AUTOSSH_POLL=60

loadEnv()
{
	history -a
	. "${HOME}/.nix-profile/dev-envs/${1}"
	export HISTFILE=$HOME/.bash_history_${1}
	if [ ! -f $HISTFILE ]; then
		echo ls > $HISTFILE
	fi
	history -c
	history -r
	export PS1="|${1}|$PS1"
}

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

#eval `keychain --noask --eval --agents ssh id_dsa david.guibert` || exit 1

# create new topic branch and open editor, commit .topmsg file
tgCreate () {
        tg create "$@" || {
                echo 'failure, starting subshell'
                $SHELL
        }
        $EDITOR .topmsg
        git add .topmsg
        git commit -m "new tg branch $1"
}
# export checked out topic branch to export/BRANCH_NAME assuming the topic was
# prefixed by t/
tgExport () {
        local branch=$(cat .git/HEAD |  sed 's@ref: refs/heads/\(t/\)\?\(.*\)@\2@')
        local prefix=export/
        local exported=${prefix}$branch
        git branch -D $exported
        tg export "$@" $exported
}

function nix() {
     if [ ! -e shell.drv  ]; then
         nix-instantiate --indirect --add-root $PWD/shell.drv shell.nix
     fi
     echo nix-shell $PWD/shell.drv --pure --run \"$@\" | sh;
}

eval "$(direnv hook bash)"
