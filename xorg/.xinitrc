#! /bin/bash

# Make caps work as ctrl/esc
setxkbmap -option 'caps:ctrl_modifier' && xcape -e 'Caps_Lock=Escape' &
setxkbmap -option 'escape:alupckeys' & # remap escape to tilde / accent grave

# Prevent touchpad from jumping around
syndaemon -i 0.5 -t -k -R -d

# Set background color
xsetroot -solid "#2d2d2d"

# Set xterm
xterm -geometry 80x50+494+51 &
xterm -geometry 80x20+494-0 &
xset r rate 200 60 # set key repeat speed

# Initialize i3
(xrdb -load ~/.Xresources) & 
exec i3
