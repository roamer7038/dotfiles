#!/bin/bash

# The following software must be installed:
# zenity xclip xdotool
# Run this script with any shortcut key.

zenity --text="Please enter text:" --entry | tr -d \n | xclip -selection clipboard
sleep 0.1
xdotool key ctrl+v
