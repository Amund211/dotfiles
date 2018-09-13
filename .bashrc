# ~/.bashrc


# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto -A --group-directories-first'
alias v='vim'
alias vi='vim'
# Logout of tty after starting x
alias startx='exec startx'
alias i3config='$EDITOR ~/.dotfiles/i3'
alias i3blocksconfig='$EDITOR ~/.dotfiles/i3blocks'
PS1='[\u@\h \W]\$ '

cdls() {
	if [ $# -eq 0 ]
	then
		builtin cd
	else
		builtin cd "$@"
	fi
	[[ $? -eq 0 ]] && ls
}
alias cd='cdls'

mkdirc() {
	mkdir $@
	cd "$1"
}

if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
	exec startx
fi
