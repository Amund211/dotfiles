#! /usr/bin/env bash

$(find -L ~/.screenlayout -type f -executable | dmenu -i -p "Select a screen layout")
