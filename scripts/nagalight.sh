#! /bin/sh

# version 1.1

set -eu

if [ -d '/sys/bus/hid/drivers/razermouse/' ]; then
	for i in {1..9}; do
		if [ -f "/sys/bus/hid/drivers/razermouse/0003:1532:0067.000$i/matrix_effect_static" ]; then
			echo -n -e '\x00\x44\xFF' > "/sys/bus/hid/drivers/razermouse/0003:1532:0067.000$i/matrix_effect_static"
			break
		fi
	done
fi
