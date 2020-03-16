# ~/.bash_profile

export PATH=$PATH:$HOME/.scripts:$HOME/bin
export EDITOR="vim"
export SUDO_EDITOR="vim"
export VISUAL="vim"
export TERMINAL="urxvt"
export BROWSER="firefox"

# Disable less history
export LESSHISTFILE="-"

# Unlimited bash history size, because why not
export HISTSIZE=
export HISTFILESIZE=
export HISTTIMEFORMAT="[%F %T %z] "

export SCREENLOCKER="i3lock -e -c 112233"

[[ -f ~/.bashrc ]] && . ~/.bashrc

# exec startx on login on tty1
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
	exec startx
else
	# Swap caps and escape when in tty
	sudo -n loadkeys ~/.scripts/ttymaps.kmap 2>/dev/null
fi

