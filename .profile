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

# https://wiki.archlinux.org/title/SSH_keys#ssh-agent
# Remember to set `AddKeysToAgent yes` in ~/.ssh/config
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > "${XDG_RUNTIME_DIR:-"$HOME"}/ssh-agent.env"
fi
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    . "${XDG_RUNTIME_DIR:-"$HOME"}/ssh-agent.env" >/dev/null
fi

# exec startx on login on tty1
# $XDG_VTNR only works on systems running systemd
# https://unix.stackexchange.com/questions/521037/what-is-the-environment-variable-xdg-vtnr#answer-521049
if [ -z "${DISPLAY:-}" ] && [ "$XDG_VTNR" = '1' ]; then
	exec startx
elif [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
	# SSH session
	:  # No-op
else
	# Swap caps and escape when in tty
	sudo -n loadkeys ~/.scripts/ttymaps.kmap 2>/dev/null
fi
