#!/bin/bash
# Install Steam launcher (optional)
# This script installs Steam client for Linux

set -e

function install_steam() {
    echo "Installing Steam launcher (optional)..."
    
    # Enable multiverse repository
    add-apt-repository multiverse
    apt-get update
    
    # Accept Steam license automatically
    echo steam steam/question select "I AGREE" | debconf-set-selections
    echo steam steam/license note '' | debconf-set-selections
    
    # Install Steam
    apt-get install -y --no-install-recommends \
        steam-launcher \
        steam-devices
    
    # Create Steam directories
    mkdir -p /opt/steam/home
    mkdir -p /opt/steam/config
    
    echo "Steam launcher installed successfully"
}

# Execute installation only if ENABLE_STEAM is true
if [ "${ENABLE_STEAM}" = "true" ]; then
    install_steam
else
    echo "Steam installation skipped (ENABLE_STEAM != true)"
fi