#!/bin/sh

set -eu

source_name='alsa_input.usb-Razer_Inc_Razer_Seiren_Mini_UC2045L03206312-00.mono-fallback'
source_volume='125%'

### RNNoise de-noising ##################
pacmd load-module module-null-sink sink_name=mic_denoised_out rate=44100
pacmd update-sink-proplist mic_denoised_out device.description='"denoised mic sink"'

pacmd load-module module-ladspa-sink sink_name=mic_raw_in sink_master=mic_denoised_out label=noise_suppressor_mono plugin=/home/amund/builds/noise-suppression-for-voice/build-x64/bin/ladspa/librnnoise_ladspa.so control=50

pacmd load-module module-loopback latency_msec=20 source="$source_name" sink=mic_raw_in channels=1 source_dont_move=true sink_dont_move=true

#pacmd load-module module-remap-source master="mic_denoised_out.monitor" source_name="denoised" source_properties=device.description="\"RNNoise denoised mic\""
pacmd load-module module-remap-source master=mic_denoised_out.monitor source_name=denoised
pacmd update-source-proplist denoised device.description='"RNNoise denoised mic"'

pacmd set-default-source denoised

pactl set-source-volume "$source_name" "$source_volume"
### RNNoise de-noising ##################
