#!/bin/bash
# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

shopt -s histappend
shopt -s no_empty_cmd_completion
shopt -s dotglob # Glob hidden files since I have ls='ls -A ...' anyway

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

# __git_complete sets __git_cmd_idx=0, so completion fns that read
# ${words[__git_cmd_idx]} to identify the subcommand (e.g. _git_pull via
# __git_complete_remote_or_refspec) see the alias name instead of pull/push/
# fetch — breaking 2nd-arg completion (`gu origin <tab>`). Splice in the real
# subcommand so they behave as if invoked through git directly.
__git_complete_alias_dispatch() {
	local cur words cword prev
	local __git_cmd_idx=1
	_get_comp_words_by_ref -n =: cur words cword prev
	words=("git" "$1" "${words[@]:1}")
	((cword++))
	"_git_$1"
}
__git_complete_alias() {
	local wrapper="__git_wrap_alias_$1"
	eval "$wrapper () { __git_complete_alias_dispatch $2; }"
	complete -o bashdefault -o default -o nospace -F "$wrapper" "$1" 2>/dev/null \
		|| complete -o default -o nospace -F "$wrapper" "$1"
}

alias g='git'
__git_complete g __git_main

# start a working area (see also: git help tutorial)
# clone     Clone a repository into a new directory
# init      Create an empty Git repository or reinitialize an existing one

# work on the current change (see also: git help everyday)
alias ga='git add'
__git_complete_alias ga add
alias gau='git add -u'
__git_complete_alias gau add
alias gap='git add --patch'
__git_complete_alias gap add

# mv        Move or rename a file, a directory, or a symlink
# restore   Restore working tree files
# rm        Remove files from the working tree and from the index

# examine the history and state (see also: git help revisions)
# bisect    Use binary search to find the commit that introduced a bug

alias gd='git diff'
__git_complete_alias gd diff
alias gds='git diff --staged'
__git_complete_alias gds diff

alias gg='git grep'
__git_complete_alias gg grep

alias gl='git log'
__git_complete_alias gl log

alias gsh='git show'
__git_complete_alias gsh show

alias gs='git status'
__git_complete_alias gs status

# grow, mark and tweak your common history
alias gb='git branch'
__git_complete_alias gb branch

alias gc='git commit'
__git_complete_alias gc commit
alias gca='git commit --amend'
__git_complete_alias gca commit
alias gcp='git commit --patch'
__git_complete_alias gcp commit
alias gcu='git commit -u'
__git_complete_alias gcu commit
alias gcau='git commit --amend -u'
__git_complete_alias gcau commit

# merge     Join two or more development histories together

alias gr='git rebase'
__git_complete_alias gr rebase
alias gri='git rebase --interactive'
__git_complete_alias gri rebase

# reset     Reset current HEAD to the specified state

gsw() {
	if [ $# -eq 0 ]; then
		{
			git branch --sort=-committerdate --format '%(refname:short)'            # Local branches, sorted by activity, showing only the refname
			git branch --sort=-committerdate --remote --format='%(refname:short)' | # Remote branches ...
				sed -E 's/^origin\/?//' |                                              # Remove origin prefix from remote branches
				awk 'NF'                                                               # Remove empty lines (origin)
		} |
			awk '!x[$0]++' |                       # Remove duplicates
			fzf --no-sort --height=25% --reverse | # Let user select
			xargs git switch                       # Switch to the chosen branch
		return
	fi
	git switch "$@"
}
__git_complete_alias gsw switch
alias gswc='git switch -c'
__git_complete_alias gswc switch

alias gt='git tag'
__git_complete_alias gt tag

# collaborate (see also: git help workflows)
alias gf='git fetch'
__git_complete_alias gf fetch

alias gp='git push'
__git_complete_alias gp push
alias gpf='git push --force-with-lease'
__git_complete_alias gpf push

alias gu='git pull'
__git_complete_alias gu pull
alias gur='git pull --rebase'
__git_complete_alias gur pull
alias guri='git pull --rebase=interactive'
__git_complete_alias guri pull

# Other
alias gst='git stash'
__git_complete_alias gst stash
alias gstp='git stash pop'
__git_complete_alias gstp stash

unset __git_complete

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

location="${red}[$yellow\u$green@$aqua\h $magenta\W$red]$reset"
# Color the $ green or red based on last exit code
prompt="\$(EXIT_CODE=\$?; if [ \$EXIT_CODE == 0 ]; then echo '$green'; else echo '$red('\$EXIT_CODE')'; fi)\$$reset "
PS1="$location$prompt"

unset location
unset prompt
unset red
unset green
unset magenta
unset aqua

if command -v zoxide &>/dev/null; then
	eval "$(zoxide init bash --cmd zox)"
	cd() {
		zox "$@" && ls
	}
	alias cdi='zoxi'

	builtin complete -F __zoxide_z_complete -o filenames -- cd
	builtin complete -r cdi &>/dev/null || builtin true
else
	echo "zoxide not installed - using builtin cd" >&2
	cd() {
		if [ $# -eq 0 ]; then
			builtin cd && ls
		else
			builtin cd "$@" && ls
		fi
	}
fi

if command -v temporal &>/dev/null; then
	source <(temporal completion bash)
fi

nvm_init_path="$NVM_INSTALL_DIR/init-nvm.sh"
if [ -f "$nvm_init_path" ]; then
	# NVM_DIR, NVM_INSTALL_DIR set by .profile
	. "$nvm_init_path"
fi
unset nvm_init_path

mkdirc() {
	mkdir "$@" && cd "$1" || return $?
}
