#!/bin/bash
# Download Wine components during build to avoid runtime downloads
# This script downloads Wine Mono, Gecko, and other components

set -e

function install_wine_components() {
    echo "Installing Wine components and winetricks..."
    
    # Install winetricks
    apt-get install -y --no-install-recommends \
        winetricks \
        cabextract \
        unzip \
        curl
    
    # Create cache directories
    mkdir -p /usr/share/wine/mono
    mkdir -p /usr/share/wine/gecko
    mkdir -p ~/.cache/winetricks
    
    # Download Wine Mono (latest version for Wine 10.x)
    echo "Downloading Wine Mono..."
    MONO_VERSION="9.3.0"
    wget -q -O /usr/share/wine/mono/wine-mono-${MONO_VERSION}-x86.msi \
        "https://dl.winehq.org/wine/wine-mono/${MONO_VERSION}/wine-mono-${MONO_VERSION}-x86.msi" || true
    
    # Download Wine Gecko (latest version)
    echo "Downloading Wine Gecko..."
    GECKO_VERSION="2.47.4"
    wget -q -O /usr/share/wine/gecko/wine-gecko-${GECKO_VERSION}-x86.msi \
        "https://dl.winehq.org/wine/wine-gecko/${GECKO_VERSION}/wine-gecko-${GECKO_VERSION}-x86.msi" || true
    wget -q -O /usr/share/wine/gecko/wine-gecko-${GECKO_VERSION}-x86_64.msi \
        "https://dl.winehq.org/wine/wine-gecko/${GECKO_VERSION}/wine-gecko-${GECKO_VERSION}-x86_64.msi" || true
    
    # Pre-download common winetricks components
    echo "Pre-downloading common Windows components..."
    
    # Create a temporary Wine prefix for downloading
    export WINEPREFIX="/tmp/wine-download"
    export WINEDLLOVERRIDES="winemenubuilder.exe=d"
    
    # Initialize Wine prefix
    wine wineboot -u 2>/dev/null || true
    
    # Download common redistributables
    winetricks --force -q \
        corefonts \
        vcrun2019 \
        vcrun2015 \
        vcrun2013 \
        vcrun2012 \
        vcrun2010 \
        vcrun2008 \
        vcrun2005 \
        dotnet48 \
        d3dcompiler_47 \
        dxvk \
        2>/dev/null || true
    
    # Clean up temporary prefix
    rm -rf /tmp/wine-download
    
    # Set proper permissions for shared Wine data
    chmod -R 755 /usr/share/wine/
    
    echo "Wine components pre-installed successfully"
}

# Execute installation
install_wine_components