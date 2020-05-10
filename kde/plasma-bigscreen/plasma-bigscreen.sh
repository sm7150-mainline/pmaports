#!/bin/sh
[ -f /etc/profile ] && . /etc/profile

export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=KDE
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=wayland

export QT_QUICK_CONTROLS_STYLE=Plasma
export QT_ENABLE_GLYPH_CACHE_WORKAROUND=1
export QT_QUICK_CONTROLS_MOBILE=true
export PLASMA_PLATFORM=phone:handset
export QT_VIRTUALKEYBOARD_STYLE=Plasma

export GRID_UNIT_PX=25
export FORCE_RIL_NUM_MODEMS=1
export PLASMA_DEFAULT_SHELL=org.kde.plasma.mycroft.bigscreen

touch /tmp/simplelogin_starting
dbus-run-session startplasma-wayland --xwayland --libinput --inputmethod maliit-server --exit-with-session=/usr/lib/libexec/startplasma-waylandsession
