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
alias nv='nvim'

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

# start a working area (see also: git help tutorial)
# clone     Clone a repository into a new directory
# init      Create an empty Git repository or reinitialize an existing one

# work on the current change (see also: git help everyday)
alias ga='git add'
__git_complete ga _git_add
alias gau='git add -u'
__git_complete gau _git_add
alias gap='git add --patch'
__git_complete gap _git_add

# mv        Move or rename a file, a directory, or a symlink
# restore   Restore working tree files
# rm        Remove files from the working tree and from the index

# examine the history and state (see also: git help revisions)
# bisect    Use binary search to find the commit that introduced a bug

alias gd='git diff'
__git_complete gd _git_diff
alias gds='git diff --staged'
__git_complete gds _git_diff

alias gg='git grep'
__git_complete gg _git_grep

alias gl='git log'
__git_complete gl _git_log

alias gsh='git show'
__git_complete gsh _git_show

alias gs='git status'
__git_complete gs _git_status

# grow, mark and tweak your common history
alias gb='git branch'
__git_complete gb _git_branch

alias gc='git commit'
__git_complete gc _git_commit
alias gca='git commit --amend'
__git_complete gca _git_commit
alias gcp='git commit --patch'
__git_complete gcp _git_commit
alias gcu='git commit -u'
__git_complete gcu _git_commit
alias gcau='git commit --amend -u'
__git_complete gcau _git_commit

# merge     Join two or more development histories together

alias gr='git rebase'
__git_complete gr _git_rebase
alias gri='git rebase --interactive'
__git_complete gri _git_rebase

# reset     Reset current HEAD to the specified state

alias gsw='git switch'
__git_complete gsw _git_switch
alias gswc='git switch -c'
__git_complete gswc _git_switch

alias gt='git tag'
__git_complete gt _git_tag

# collaborate (see also: git help workflows)
alias gf='git fetch'
__git_complete gf _git_fetch

alias gp='git push'
__git_complete gp _git_push
alias gpf='git push --force-with-lease'
__git_complete gpf _git_push

alias gu='git pull'
__git_complete gu _git_pull

# Other
alias gst='git stash'
__git_complete gst _git_stash
alias gstp='git stash pop'
__git_complete gstp _git_stash



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


if command -v zoxide &> /dev/null; then
	eval "$(zoxide init bash --cmd zox)"
	cd() {
		zox $@ && ls
	}
	alias cdi='zoxi'

	builtin complete -F __zoxide_z_complete -o filenames -- cd
	builtin complete -r cdi &>/dev/null || builtin true
else
	echo "zoxide not installed - using builtin cd" >&2
	cd() {
		if [ $# -eq 0 ]
		then
			builtin cd
		else
			builtin cd "$@"
		fi
		[ $? -eq 0 ] && ls
	}
fi


mkdirc() {
	mkdir $@
	cd "$1"
}

