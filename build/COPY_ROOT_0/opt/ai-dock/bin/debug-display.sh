#!/bin/bash

echo "=== Display Debug Script ==="
echo "Date: $(date)"
echo ""

echo "1. Environment Variables:"
echo "DISPLAY=$DISPLAY"
echo "HOME=$HOME"
echo "USER=$USER"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo ""

echo "2. X Server Check:"
ps aux | grep -E "Xorg|Xvfb|Xvnc" | grep -v grep || echo "No X server processes found"
echo ""

echo "3. X11 Sockets:"
ls -la /tmp/.X11-unix/ 2>/dev/null || echo "No X11 sockets found"
echo ""

echo "4. Display Test:"
DISPLAY=${DISPLAY:-:0} xdpyinfo -display $DISPLAY 2>&1 | head -20 || echo "Cannot connect to display"
echo ""

echo "5. KDE Processes:"
ps aux | grep -E "plasmashell|kwin_x11|plasma_session" | grep -v grep || echo "No KDE processes found"
echo ""

echo "6. Simple X Test:"
echo "Trying to run xeyes..."
DISPLAY=${DISPLAY:-:0} timeout 2 xeyes &
XEYES_PID=$!
sleep 1
if ps -p $XEYES_PID > /dev/null 2>&1; then
    echo "xeyes is running (PID: $XEYES_PID)"
    kill $XEYES_PID 2>/dev/null
else
    echo "xeyes failed to start"
fi
echo ""

echo "7. VNC Check:"
ps aux | grep -E "vncserver|kasmvnc" | grep -v grep || echo "No VNC processes found"
echo ""

echo "8. D-Bus Check:"
echo "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
ls -la /tmp/dbus-session 2>/dev/null || echo "No dbus socket found"
echo ""

echo "9. Screenshot Attempt:"
DISPLAY=${DISPLAY:-:0} import -window root /tmp/screenshot.png 2>&1 && echo "Screenshot saved to /tmp/screenshot.png" || echo "Screenshot failed"
echo ""

echo "10. OpenGL Check:"
DISPLAY=${DISPLAY:-:0} glxinfo 2>&1 | grep -E "OpenGL vendor|OpenGL renderer|direct rendering" || echo "OpenGL info not available"
echo ""

echo "=== End Debug ==="