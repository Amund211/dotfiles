# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

shopt -s histappend
shopt -s no_empty_cmd_completion
shopt -s dotglob  # Glob hidden files since I have ls='ls -A ...' anyway

# Don't put duplicate lines or lines starting with a space in the history
HISTCONTROL=ignoreboth

# Unlimited bash history size, because why not
# Duplicated from .profile so it it set even when using su
export HISTSIZE=
export HISTFILESIZE=
export HISTTIMEFORMAT='[%F %T %z] '

# vi-bindings
set -o vi

alias ls='ls -A --color=auto --group-directories-first'
alias ll='ls -l'
alias grep='grep --color=auto'
alias rm='rm -I'
alias mv='mv --interactive'
alias cp='cp --interactive'
alias p='sudo pacman'
alias trim='sudo fstrim -A'
alias h='$TERMINAL >/dev/null 2>/dev/null & disown $!'
alias pw='watch -n 1 ping -c 1 8.8.8.8'
alias clip='xclip -selection primary -o | xclip -selection clipboard'
alias sel='xclip -selection clipboard -o | xclip -selection primary'

# Logout of tty after starting x
alias startx='exec startx'
alias i3config='$EDITOR ~/.dotfiles/i3'
alias i3blocksconfig='$EDITOR ~/.dotfiles/i3blocks'

red='\[\e[31m\]'
green='\[\e[32m\]'
yellow='\[\e[33m\]'
magenta='\[\e[35m\]'
aqua='\[\e[36m\]'

bright_green='\[\e[92m\]'
bright_red='\[\e[91m\]'

reset='\[\e[0m\]'

location="$red[$yellow\u$green@$aqua\h $magenta\W$red]$reset"
# Color the $ green or red based on last exit code
prompt="\$(EXIT_CODE=\$?; if [ \$EXIT_CODE == 0 ]; then echo '$bright_green'; else echo '$bright_red('"\$EXIT_CODE"')'; fi)\$$reset "
PS1="$location$prompt"

unset location
unset prompt
unset red
unset green
unset magenta
unset aqua
unset bright_green
unset bright_red

cdls() {
	if [ $# -eq 0 ]
	then
		builtin cd
	else
		builtin cd "$@"
	fi
	[ $? -eq 0 ] && ls
}
alias cd='cdls'

mkdirc() {
	mkdir $@
	cd "$1"
}

