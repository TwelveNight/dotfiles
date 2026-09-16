#!/bin/bash
slurp -d -b "#00000000" -c "#82AAFFFF" -s "#00000044" -f "hyprctl keyword windowrule unset, areaterm
hyprctl keyword windowrule animation popin, areaterm
hyprctl keyword windowrule move %x %y, areaterm
hyprctl keyword windowrule float, areaterm
hyprctl keyword windowrule size %w %h, areaterm
hyprctl keyword windowrule noborder,areaterm
hyprctl keyword windowrule rounding 10,areaterm
hyprctl keyword windowrule opacity 0.8 0.8,areaterm
hyprctl keyword windowrule noblur,areaterm
kitty --class areaterm" | bash
