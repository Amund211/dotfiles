#! /usr/bin/sh

# This script is called by i3 on startup.

# Swap caps and escape
setxkbmap -option caps:swapescape

# Map the menu button to right super as well.
xmodmap -e 'keycode 135 = Super_R NoSymbol Super_R'
#keycode 135 = Super_R NoSymbol Super_R
