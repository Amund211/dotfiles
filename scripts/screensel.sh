#! /usr/bin/env bash

$(find ~/.screenlayout -type f -executable | dmenu -i -p "Select a screen layout")
