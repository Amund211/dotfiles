# ~/.bash_profile

export PATH=$PATH:$HOME/.scripts:$HOME/bin
export EDITOR="vim"
export SUDO_EDITOR="vim"
export VISUAL="vim"
export TERMINAL="urxvt"
export BROWSER="firefox"

[[ -f ~/.bashrc ]] && . ~/.bashrc

# exec startx on login on tty1
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
	exec startx
fi

# Swap caps and escape when in tty
sudo -n loadkeys ~/.scripts/ttymaps.kmap 2>/dev/null

