#! /usr/bin/env bash

set -eux

# inc/dec the screen brightness exponentially, to appear
# as a linear progression to our logatrithmic eyes

steps=("1" "139" "373" "1003" "2692" "7225" "19393")
steps=("1" "2" "4" "8" "16" "32" "64" "100")
rawBrightness=$(xbacklight -get)
currBright="$(printf "%.*f\n" "0" "$rawBrightness")"
echo $currBright

currStep='0'
# Finding current brightness step
for s in ${!steps[@]}; do
	[[ "$currBright" = "${steps[${s}]}" ]] && currStep=${s}
done

amtSteps=${#steps[@]}
maxStep=$(($amtSteps - 1))

# Change (1,2,-1,-2...) is taken as first parameter
# otherwise increments by one as default
change=${1:-1}

nextStep=$(($currStep + $change))

# Confining nextStep in set {0,...amtSteps-1}
nextStep=$(($nextStep < 0 ? 0 : $nextStep))
nextStep=$(($nextStep >= $maxStep ? $maxStep : $nextStep))

# No change in step
(($currStep == $nextStep)) && exit 0

nextBright=${steps[$nextStep]}
xbacklight -set "$nextBright"
