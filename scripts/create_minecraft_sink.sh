#!/bin/sh

# Dragonfly
# main_sink='alsa_output.usb-AudioQuest_AudioQuest_DragonFly_Black_v1.5_AQDFBL0100102437-01.iec958-stereo'

# Front jack
main_sink='alsa_output.pci-0000_09_00.4.analog-stereo'

# Screen speakers
#main_sink='alsa_output.pci-0000_07_00.1.hdmi-stereo-extra2'

### Minecraft isolated ####################

pacmd load-module module-null-sink sink_name=minecraft_sink
pacmd update-sink-proplist minecraft_sink device.description='"Minecraft sounds"'

pacmd load-module module-loopback latency_msec=20 source=minecraft_sink.monitor sink=$main_sink

### Minecraft isolated ####################
