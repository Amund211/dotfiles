#! /usr/bin/sh

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
