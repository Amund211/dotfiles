# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

shopt -s histappend
shopt -s no_empty_cmd_completion

# Don't put duplicate lines or lines starting with a space in the history
HISTCONTROL=ignoreboth

# vi-bindings
set -o vi

alias ls='ls -A --color=auto --group-directories-first'
alias ll='ls -l'
alias grep='grep --color=auto'
alias rm='rm -I'
alias mv='mv --interactive'
alias cp='cp --interactive'
alias v='vim'
alias vi='vim'
alias p='sudo pacman'
alias trim='sudo fstrim -A'
alias h='$TERMINAL & disown'
alias pw='watch -n 1 ping -c 1 8.8.8.8'
alias clip='xclip -selection primary -o | xclip -selection clipboard'
alias sel='xclip -selection clipboard -o | xclip -selection primary'

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

