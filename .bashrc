# ~/.bashrc: executed by bash(1) for non-login shells.

# User specific environment and startup programs
export PATH=$HOME/bin:$PATH
export PATH=$HOME/cmake-3.5.1-Linux-x86_64/bin:$PATH
export MANPATH=$HOME/man:$MANPATH
export EDITOR=vim

source /opt/intel/parallel_studio_xe_2016.2.062/psxevars.sh >/dev/null
export PATH=/home_nfs/isv/allinea/forge-6.0.2/bin:$PATH

# User specific aliases and functions

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

#eval `keychain --noask -q --eval id_dsa david.guibert`

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
PS1=""
PS1+='\[\033[01;37m\]$(exit=$?; if [[ $exit == 0 ]]; then echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗ $exit"; fi)'
PS1+='${GIT_DIR:+ \[\033[00;32m\]vcsh:$(basename $GIT_DIR)}'
PS1+='${SLURM_NODELIST:+ \[\033[01;34m\][$SLURM_NODELIST]\[\033[00m\]}'
PS1+=' \[\033[00;32m\]\u@\h\[\033[01;34m\] \W '
if !  command -v __git_ps1 >/dev/null; then
# source $HOME/code/git/contrib/completion/git-prompt.sh
  source $HOME/code/git-prompt.sh
fi
PS1+='$(__git_ps1 "|%s|")'
PS1+='$\[\033[00m\] '

export PS1
case $TERM in
	rxvt|*term)
		trap 'echo -ne "\e]0;$BASH_COMMAND\007"' DEBUG
	;;
esac

eval `dircolors`
alias ls='ls --color'

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

#export AWT_TOOLKIT=MToolkit

if hash direnv 2> /dev/null; then
  eval "$(direnv hook bash)"
fi
