#!/bin/sh

### RNNoise de-noising ##################
pacmd load-module module-null-sink sink_name=mic_denoised_out rate=44100

pacmd load-module module-ladspa-sink sink_name=mic_raw_in sink_master=mic_denoised_out label=noise_suppressor_mono plugin=/home/amund/builds/noise-suppression-for-voice/build-x64/bin/ladspa/librnnoise_ladspa.so control=50

pacmd load-module module-loopback latency_msec=20 source=alsa_input.usb-0d8c_C-Media_USB_Headphone_Set-00.mono-fallback sink=mic_raw_in channels=1 source_dont_move=true sink_dont_move=true

#pacmd load-module module-remap-source master="mic_denoised_out.monitor" source_name="denoised" source_properties=device.description="\"RNNoise denoised mic\""
pacmd load-module module-remap-source master=mic_denoised_out.monitor source_name=denoised
pacmd update-source-proplist denoised device.description='"RNNoise denoised mic"'

pacmd set-default-source denoised
### RNNoise de-noising ##################
