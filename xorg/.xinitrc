#! /bin/bash

# Prevent touchpad from jumping around
syndaemon -i 0.5 -t -k -R -d

# Set background color
xsetroot -solid "#2d2d2d"

# Initialize i3
(xrdb -load ~/.Xresources) & 
(xmodmap ~/.Xmodmap) &
exec i3
