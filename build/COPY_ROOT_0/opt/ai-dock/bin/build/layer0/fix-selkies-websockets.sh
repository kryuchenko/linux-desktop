#!/bin/bash
# Fix websockets compatibility for selkies-gstreamer with Python 3.10+

set -e

function fix_selkies_websockets() {
    echo "Fixing websockets compatibility for selkies-gstreamer..."
    
    # Update websockets in selkies environment
    if [ -d "$SELKIES_VENV" ]; then
        echo "Updating websockets in selkies environment..."
        "$SELKIES_VENV_PIP" install --no-cache-dir --upgrade "websockets>=11"
    fi
    
    # Update websockets in serviceportal environment if it exists
    if [ -d "/opt/environments/python/serviceportal" ]; then
        echo "Updating websockets in serviceportal environment..."
        /opt/environments/python/serviceportal/bin/pip install --no-cache-dir --upgrade "websockets>=11"
    fi
    
    # Install missing audio processing library
    apt-get update
    apt-get install -y --no-install-recommends libwebrtc-audio-processing1
    
    echo "Websockets compatibility fix completed"
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    fix_selkies_websockets
fi