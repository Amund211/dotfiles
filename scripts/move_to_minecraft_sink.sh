#!/bin/sh
pactl list sink-inputs | while read -r line ; do
	if res="$(echo $line | grep -oP 'Sink Input #\K[^$]+')"; then
		id="$res"
		echo parsing id $id
	fi
	if echo $line | grep -oP 'application.process.binary = "java"'; then
		echo moving $id
		pactl move-sink-input "$id" minecraft_sink
		break
	fi
done
