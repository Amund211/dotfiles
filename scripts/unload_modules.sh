#!/bin/sh

pacmd unload-module module-remap-source
pacmd unload-module module-loopback
pacmd unload-module module-ladspa-sink
pacmd unload-module module-null-sink
pacmd set-default-source alsa_input.usb-0d8c_C-Media_USB_Headphone_Set-00.mono-fallback
