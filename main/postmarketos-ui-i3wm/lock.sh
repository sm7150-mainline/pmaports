#!/bin/sh

FILE=~/tmp/screenoff
if [ -f $FILE ]; then
    xinput set-prop 8 "Device Enabled" 1
    xset dpms force on
    rm ~/.screenoff
else
    xset dpms force off
    xinput set-prop 8 "Device Enabled" 0
    touch ~/.screenoff
fi
