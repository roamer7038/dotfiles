#!/bin/sh

# Screen Saver:
# xset s <timeout> <cycle>
xset s 300 300

# DPMS:
# xset s <standby> <suspend> <off>
xset dpms 300 300 300

# Key Repeat:
# xset r rate <delay> <rate>
xset r rate 300 30

# Key Remap:
xmodmap ~/.Xmodmap
