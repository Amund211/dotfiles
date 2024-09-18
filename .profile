# ~/.profile

export PATH="$HOME/bin:$PATH:$HOME/.dotfiles/scripts"
export EDITOR='vim'
export SUDO_EDITOR='vim'
export VISUAL='vim'
export TERMINAL='urxvt'
export BROWSER='firefox'

export SCREENLOCKER='i3lock -e -c 112233'

# Editor used by vite-plugin-react-click-to-component
export LAUNCH_EDITOR="$HOME/.dotfiles/scripts/launch_editor.py"

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

# Run nvm if it exists
# NOTE: The installer seems to put it in ~/.nvm, but the AUR package puts it in usr/share
NVM_INSTALL_DIR='/usr/share/nvm'
if [ -s "$NVM_INSTALL_DIR/nvm.sh" ]; then
	export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
	. "$NVM_INSTALL_DIR/nvm.sh"
fi
unset NVM_INSTALL_DIR

# exec startx on login on tty1
# $XDG_VTNR only works on systems running systemd
# https://unix.stackexchange.com/questions/521037/what-is-the-environment-variable-xdg-vtnr#answer-521049
if [ -n "${DISPLAY:-}" ]; then
	# Already loaded
	:
elif [ -z "${DISPLAY:-}" ] && [ "$XDG_VTNR" = '1' ]; then
	exec startx
elif [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
	# SSH session
	:  # No-op
else
	# Swap caps and escape when in tty
	sudo -n loadkeys ~/.dotfiles/scripts/ttymaps.kmap 2>/dev/null
fi
