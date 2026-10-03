#!/bin/sh
#
# Wrapper script for Zen Browser (source build)
#

MOZILLA_FIVE_HOME="@MOZILLA_FIVE_HOME@"
DEFAULT_WAYLAND="@DEFAULT_WAYLAND@"

##
## Enable Wayland backend?
##
if [ "${DEFAULT_WAYLAND}" = "1" ] && [ -z "${MOZ_DISABLE_WAYLAND}" ]; then
	if [ -n "${WAYLAND_DISPLAY}" ]; then
		export MOZ_ENABLE_WAYLAND=1
	fi
fi

##
## Use D-Bus remote exclusively when there's Wayland display.
##
if [ -n "${WAYLAND_DISPLAY}" ]; then
	export MOZ_DBUS_REMOTE=1
fi

##
## Allow downgrading of profiles (e.g. after switching back from
## a newer Zen/Firefox version).
##
export MOZ_ALLOW_DOWNGRADE=1

exec "${MOZILLA_FIVE_HOME}/zen" "$@"
