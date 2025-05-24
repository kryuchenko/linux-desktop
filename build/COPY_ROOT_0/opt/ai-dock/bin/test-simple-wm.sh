#!/bin/bash

echo "=== Simple Window Manager Test ==="

# Source environment
source /opt/ai-dock/etc/environment.sh 2>/dev/null || echo "No environment.sh found"

# Kill any existing window managers
echo "Stopping existing window managers..."
pkill -f plasmashell 2>/dev/null
pkill -f kwin 2>/dev/null
pkill -f openbox 2>/dev/null
sleep 2

# Set display
export DISPLAY=${DISPLAY:-:0}
echo "Using DISPLAY=$DISPLAY"

# Test with openbox (simple window manager)
echo "Starting openbox..."
openbox --sm-disable &
OPENBOX_PID=$!
sleep 2

if ps -p $OPENBOX_PID > /dev/null 2>&1; then
    echo "Openbox started successfully (PID: $OPENBOX_PID)"
    
    # Try to run a simple application
    echo "Starting xterm..."
    xterm -geometry 80x24+100+100 -title "Test Terminal" &
    XTERM_PID=$!
    sleep 2
    
    if ps -p $XTERM_PID > /dev/null 2>&1; then
        echo "xterm started successfully (PID: $XTERM_PID)"
        echo ""
        echo "SUCCESS: Simple window manager test passed!"
        echo "If you can see this via VNC/WebRTC, the display stack is working."
        echo "The issue is specific to KDE Plasma."
    else
        echo "xterm failed to start"
    fi
else
    echo "Openbox failed to start"
fi

echo ""
echo "Processes running:"
ps aux | grep -E "openbox|xterm" | grep -v grep

echo ""
echo "Leave running for testing. Press Ctrl+C to stop."
sleep infinity