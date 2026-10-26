#!/usr/bin/env bash
# gpu-load.sh — i3blocks blocklet: NVIDIA GPU and memory load from nvidia-smi.
# Prints nothing on machines without nvidia-smi, so the block hides.
# Color: yellow at T_WARN (default 70), red at T_CRIT (default 90) percent.

command -v nvidia-smi >/dev/null || exit 0

IFS=', ' read -r gpu mem < <(nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv,noheader,nounits) || exit 0

echo "${gpu}% ${mem}%"
echo "${gpu}%"

max=$((gpu > mem ? gpu : mem))
if [ "$max" -ge "${T_CRIT:-90}" ]; then
	echo '#FF0000'
elif [ "$max" -ge "${T_WARN:-70}" ]; then
	echo '#FFFC00'
fi
