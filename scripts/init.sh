#! /usr/bin/bash

case "$(uname -n)" in
miniluv)
	nagaIDs=$(xinput --list | awk '/Razer Razer Naga Trinity  .*pointer/ {print $7}' | sed 's/id=\(.*\)/\1/')

	nagaID=$(echo -n $nagaIDs | python -c "import sys;print(min(int(i) for i in sys.stdin.readline().split(' ')))")

	if [ ! -z "$nagaID" ]; then
		# Only exec if the mouse is found
		~/.dotfiles/scripts/nagalight.sh
		exec xinput test $nagaID | awk '/button release [13]/ { print; fflush(stdout) }' | python ~/programming/xcountclicks/piper.py
	else
		#echo $(date) >> ~/.failedmouseattach.log
		:
	fi

	# 6 * 5 = 30s of timeout before night-night
	# sudo hdparm -S 6 /dev/disk/by-id/ata-ST2000DM001-9YN164_S1E0F4YR >> ~/hdparm.out 2>> hdparm.err &
	;;
ficdep)
	/usr/bin/solaar -w hide &

	/home/amund/.dotfiles/scripts/git-maintenance.sh &

	/home/amund/.dotfiles/scripts/start-slack.sh &

	/home/amund/.dotfiles/scripts/break-reminder.sh $((30 * 60)) &

	# Owns the repository list and the startup stagger; --restart to pick up changes later.
	/home/amund/.dotfiles/scripts/start-pr-review.sh &

	socat tcp-listen:6432,reuseaddr,fork tcp:localhost:5432 &

	/usr/bin/dunst &

	/home/amund/bin/worktime &

	/usr/bin/picom &

	tmux new-session -d -s claude 'cd ~/git/ignite/agent-main/remote && claude --remote-control'

	disown -a
	;;
esac
