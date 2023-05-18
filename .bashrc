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

alias sudo='sudo -v; sudo '
alias ls='ls -A --human-readable --color=auto --group-directories-first'
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

# Git stuff
if [ -f /usr/share/bash-completion/completions/git ]; then
	source /usr/share/bash-completion/completions/git
else
	echo ERROR
	__git_complete() {
		:
	}
fi

alias g='git'
__git_complete g __git_main
alias gs='git status'
__git_complete gs _git_status
alias gd='git diff'
__git_complete gd _git_diff
alias gds='git diff --staged'
__git_complete gds _git_diff
alias ga='git add'
__git_complete ga _git_add
alias gap='git add --patch'
__git_complete gap _git_add
alias gc='git commit'
__git_complete gc _git_commit
alias gca='git commit --amend'
__git_complete gca _git_commit
alias gcp='git commit --patch'
__git_complete gcp _git_commit
alias gl='git log'
__git_complete gl _git_log
alias gsw='git switch'
__git_complete gsw _git_switch
alias gr='git rebase'
__git_complete gr _git_rebase
alias gri='git rebase --interactive'
__git_complete gri _git_rebase
alias gp='git push'
__git_complete gp _git_push
alias gu='git pull'
__git_complete gu _git_pull

# Logout of tty after starting x
alias startx='exec startx'
alias i3config='$EDITOR ~/.dotfiles/i3'
alias i3blocksconfig='$EDITOR ~/.dotfiles/i3blocks'

red='\[\e[91m\]'
green='\[\e[92m\]'
yellow='\[\e[93m\]'
magenta='\[\e[95m\]'
aqua='\[\e[96m\]'

reset='\[\e[0m\]'

location="$red[$yellow\u$green@$aqua\h $magenta\W$red]$reset"
# Color the $ green or red based on last exit code
prompt="\$(EXIT_CODE=\$?; if [ \$EXIT_CODE == 0 ]; then echo '$green'; else echo '$red('"\$EXIT_CODE"')'; fi)\$$reset "
PS1="$location$prompt"

unset location
unset prompt
unset red
unset green
unset magenta
unset aqua

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

