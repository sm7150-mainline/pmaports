#!/bin/sh

# Firefox does run with xwayland by default on Gnome, this setting
# makes it pick the wayland backend without setting GDK_BACKEND=wayland
# which causes more issues in the Gnome stack
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
	export MOZ_ENABLE_WAYLAND=1
fi
