#!/bin/bash

# We don't have full control because of dbus
# Best effort to allow stopping and restarting

trap cleanup EXIT

SERVICE_NAME="KDE Plasma Desktop"

function cleanup() {
    sudo kill $(jobs -p) > /dev/null 2>&1 &
    wait -n
    # Cause X to restart, taking dependent processes with it
    sudo pkill supervisor-x-server > /dev/null 2>&1
    sudo pkill plasmashell > /dev/null 2>&1
}

function start() {
    source /opt/ai-dock/etc/environment.sh
    if [[ ${SERVERLESS,,} = "true" ]]; then
        printf "Refusing to start $SERVICE_NAME in serverless mode\n"
        exec sleep 10
    fi
    
    printf "Starting ${SERVICE_NAME}...\n"
    
    until [[ -S "$DBUS_SOCKET" ]]; do
        printf "Waiting for dbus socket...\n"
        sleep 1
    done
    
    until [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; do
        printf "Waiting for X11 socket...\n"
        sleep 1
    done
    source /opt/ai-dock/etc/environment.sh
    
    # Ensure D-Bus session is available
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        eval "$(dbus-launch --sh-syntax)"
        export DBUS_SESSION_BUS_ADDRESS
        export DBUS_SESSION_BUS_PID
    fi
    
    rm -rf ~/.cache
    
    # Ensure required KDE files and directories exist
    mkdir -p ~/.config ~/.local/share ~/.cache
    touch ~/.config/startplasma-x11rc
    chmod 644 ~/.config/startplasma-x11rc
    if [ ! -f ~/.config/kdeglobals ]; then
        echo "[General]" > ~/.config/kdeglobals
    fi
    chmod 644 ~/.config/kdeglobals
    mkdir -p ~/.config/autostart
    
    # Fix ownership for current user
    chown -R $(whoami):$(id -gn) ~/.config ~/.local ~/.cache
  
    # Start KDE
    # Use VirtualGL to run the KDE desktop environment with OpenGL if the GPU is available, otherwise use OpenGL with llvmpipe
    xmode="$(cat /tmp/.X-mode)"
    
    export QT_LOGGING_RULES='*.debug=false;qt.qpa.*=false'
    
    if [[ $xmode == "proxy" ]]; then
        export VGL_FPS="${DISPLAY_REFRESH}"
        exec /usr/bin/vglrun \
            -d "${VGL_DISPLAY:-egl}" \
            +wm \
            /usr/bin/startplasma-x11
    else
        exec /usr/bin/startplasma-x11
    fi
}

start 2>&1