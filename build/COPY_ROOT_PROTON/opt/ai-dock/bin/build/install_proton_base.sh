#!/bin/bash
# Install base Proton/Wine dependencies
# This script installs Wine staging and required 32-bit libraries

set -e

function install_proton_base() {
    echo "Installing Proton base dependencies..."
    
    # Enable 32-bit architecture
    dpkg --add-architecture i386
    apt-get update
    
    # Add Wine repository (using modern method for Ubuntu 22.04)
    # Download and add the new WineHQ key
    wget -O- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor | tee /usr/share/keyrings/winehq.gpg > /dev/null
    
    # Add Wine repository for Ubuntu 22.04 (jammy) with the correct key
    echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/ubuntu/ jammy main" > /etc/apt/sources.list.d/winehq.list
    apt-get update
    
    # Install Wine staging (includes both 32 and 64-bit)
    apt-get install -y --no-install-recommends \
        winehq-staging \
        wine-staging \
        wine-staging-i386 \
        wine-staging-amd64
    
    # Install essential 32-bit libraries for gaming
    apt-get install -y --no-install-recommends \
        libgnutls30:i386 \
        libldap-2.4-2:i386 \
        libgpg-error0:i386 \
        libxml2:i386 \
        libasound2-plugins:i386 \
        libsdl2-2.0-0:i386 \
        libfreetype6:i386 \
        libdbus-1-3:i386 \
        libsqlite3-0:i386 \
        libglu1-mesa:i386 \
        libglu1-mesa \
        libgles2-mesa:i386 \
        libosmesa6:i386 \
        libncurses5:i386 \
        libncurses6:i386
    
    # Additional libraries for better compatibility
    apt-get install -y --no-install-recommends \
        libfaudio0:i386 \
        libgstreamer1.0-0:i386 \
        libgstreamer-plugins-base1.0-0:i386 \
        gstreamer1.0-plugins-good:i386 \
        gstreamer1.0-plugins-bad:i386 \
        gstreamer1.0-plugins-ugly:i386 \
        libvkd3d1:i386 \
        libvkd3d1
    
    echo "Proton base dependencies installed successfully"
}

# Execute installation
install_proton_base