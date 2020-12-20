# ~/.profile

export PATH="$PATH:$HOME/.scripts:$HOME/bin"
export EDITOR='vim'
export SUDO_EDITOR='vim'
export VISUAL='vim'
export TERMINAL='urxvt'
export BROWSER='firefox'

export SCREENLOCKER='i3lock -e -c 112233'

# Disable less history
export LESSHISTFILE='-'

# Unlimited bash history size, because why not
export HISTSIZE=
export HISTFILESIZE=
export HISTTIMEFORMAT='[%F %T %z] '

[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# exec startx on login on tty1
# $XDG_VTNR only works on systems running systemd
# https://unix.stackexchange.com/questions/521037/what-is-the-environment-variable-xdg-vtnr#answer-521049
if [ -z "${DISPLAY:-}" ] && [ "$XDG_VTNR" = '1' ]; then
	exec startx
else
	# Swap caps and escape when in tty
	sudo -n loadkeys ~/.scripts/ttymaps.kmap 2>/dev/null
fi

