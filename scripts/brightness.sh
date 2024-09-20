#! /usr/bin/env bash

# inc/dec the screen brightness exponentially, to appear
# as a linear progression to our logatrithmic eyes

steps=("1" "3" "6" "10" "16" "25" "45" "85" "150" "255")
brightnessLoc=/sys/class/backlight/radeon_bl0/brightness
currBright=$(cat $brightnessLoc)

# Finding current brightness step
for s in ${!steps[@]}; do
	[[ "$currBright" = "${steps[${s}]}" ]] && currStep=${s}
done

amtSteps=${#steps[@]}
maxStep=$(($amtSteps-1))

# Change (1,2,-1,-2...) is taken as first parameter
# otherwise increments by one as default
change=${1:-1}

nextStep=$(($currStep+$change))

# Confining nextStep in set {0,...amtSteps-1}
nextStep=$(($nextStep<0?0:$nextStep))
nextStep=$(($nextStep>=$maxStep?$maxStep:$nextStep))

# No change in step
(( $currStep == $nextStep )) && exit 0

nextBright=${steps[$nextStep]}
echo $nextBright | sudo tee $brightnessLoc

