#!/bin/bash

zenity --text="Please enter text:" --entry | tr -d \n | xclip -selection clipboard
sleep 0.1
xdotool key ctrl+v
