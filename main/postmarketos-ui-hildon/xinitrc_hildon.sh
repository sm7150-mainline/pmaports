#!/bin/sh

# Set default wallpapers
mkdir -p ~/.backgrounds
for i in 1 2 3 4; do
	source=/usr/share/themes/alpha/backgrounds/wallpaper$i.png
	destination=~/.backgrounds/background-$i.png
	[ -e "$destination" ] || ln -s "$source" "$destination"
done

# Start dbus and export its environment variables
eval "$(dbus-launch --sh-syntax --exit-with-session)"

# Start X11 with Hildon
export LC_MESSAGES=en_US.UTF-8
exec hildon-desktop
