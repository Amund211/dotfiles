#!/bin/sh

set -eu

# Front jack
output_sink='alsa_output.pci-0000_09_00.4.analog-stereo'

# Screen speakers
#output_sink='alsa_output.pci-0000_07_00.1.hdmi-stereo-extra2'

# Denoised mic
mic_source='denoised'

# Raw mic
# Briste atm, need to make it a sink
# mic_sink='alsa_input.usb-Razer_Inc_Razer_Seiren_Mini_UC2045L03206312-00.mono-fallback'

### Application mix ######################
# Sink that we can play application audio to
pacmd load-module module-null-sink sink_name=application_mix_sink
pacmd update-sink-proplist application_mix_sink device.description='"application mix sink"'

pacmd load-module module-null-sink sink_name=application_sink
pacmd update-sink-proplist application_sink device.description='"Application sink"'

# Mix the mic and application audio
# pacmd load-module module-combine-sink sink_name=application_mix_sink slaves=application_sink,$mic_sink
# pacmd update-sink-proplist application_mix_sink device.description='"application mix sink"'

# Loop back the application audio to our main sink (so we can hear it)
pacmd load-module module-loopback latency_msec=20 source=application_sink.monitor sink=$output_sink

# Loop back the application audio to the mix sink (so we can hear it)
pacmd load-module module-loopback latency_msec=20 source=application_sink.monitor sink=application_mix_sink

# Loop back the mic audio to the mix
pacmd load-module module-loopback latency_msec=20 source=$mic_source sink=application_mix_sink

# Remap the sink to a source so we can play it back for others
pacmd load-module module-remap-source master=application_mix_sink.monitor source_name=application_mix_source
pacmd update-source-proplist application_mix_source device.description='"Application mix source"'

### Application mix ######################

source_volume='125%'

# pactl set-source-volume application_mix_source "$source_volume"
