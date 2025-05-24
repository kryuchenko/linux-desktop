#!/bin/bash

# Display configuration
export DISPLAY="${DISPLAY:-:0}"
export VNC_DISPLAY="${VNC_DISPLAY:-:1}"
export DISPLAY_SIZEW="${DISPLAY_SIZEW:-1920}"
export DISPLAY_SIZEH="${DISPLAY_SIZEH:-1080}"
export DISPLAY_REFRESH="${DISPLAY_REFRESH:-60}"
export DISPLAY_DPI="${DISPLAY_DPI:-96}"
export DISPLAY_CDEPTH="${DISPLAY_CDEPTH:-24}"

# User configuration
export USER_NAME="${USER_NAME:-root}"
export USER_PASSWORD="${USER_PASSWORD:-password}"
export HOME="${HOME:-/root}"

# D-Bus configuration
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/tmp/dbus-session}"
export DBUS_SOCKET="${DBUS_SOCKET:-/tmp/dbus-session}"

# VGL configuration for virtual GL rendering
export VGL_DISPLAY="${VGL_DISPLAY:-egl}"

# XDG directories
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$USER_NAME}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Create XDG directories if they don't exist
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
chmod 700 "$XDG_RUNTIME_DIR"

# Qt/KDE specific
export QT_X11_NO_MITSHM=1
export QT_GRAPHICSSYSTEM=native

# Path configuration
export PATH="/usr/games:$PATH"