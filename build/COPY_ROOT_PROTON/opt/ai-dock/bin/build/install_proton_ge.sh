#!/bin/bash
# Download and install Proton GE 10-3
# This script installs Proton GE for system-wide use

set -e

PROTON_GE_VERSION="GE-Proton10-3"
PROTON_DIR="/opt/proton-ge"
STEAM_COMPAT_DIR="/opt/steam/compatibilitytools.d"

function install_proton_ge() {
    echo "Installing Proton GE ${PROTON_GE_VERSION}..."
    
    # Create directories
    mkdir -p ${PROTON_DIR}
    mkdir -p ${STEAM_COMPAT_DIR}
    
    # Download Proton GE
    cd /tmp
    echo "Downloading Proton GE ${PROTON_GE_VERSION}..."
    wget -q --show-progress https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_GE_VERSION}/${PROTON_GE_VERSION}.tar.gz
    
    # Extract to Steam compatibility tools directory
    echo "Extracting Proton GE..."
    tar -xzf ${PROTON_GE_VERSION}.tar.gz -C ${STEAM_COMPAT_DIR}
    
    # Create symlink for system-wide access
    ln -sf ${STEAM_COMPAT_DIR}/${PROTON_GE_VERSION} ${PROTON_DIR}/current
    
    # Set permissions
    chmod -R 755 ${STEAM_COMPAT_DIR}/${PROTON_GE_VERSION}
    
    # Create wrapper scripts for easier access
    mkdir -p /usr/local/bin
    
    # Create proton wrapper
    cat > /usr/local/bin/proton << 'EOF'
#!/bin/bash
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${STEAM_COMPAT_CLIENT_INSTALL_PATH:-/opt/steam}"
export STEAM_COMPAT_DATA_PATH="${STEAM_COMPAT_DATA_PATH:-/workspace/.proton}"
exec /opt/proton-ge/current/proton "$@"
EOF
    chmod +x /usr/local/bin/proton
    
    # Create wine wrapper using Proton's wine
    cat > /usr/local/bin/proton-wine << 'EOF'
#!/bin/bash
export WINEPREFIX="${WINEPREFIX:-/workspace/.wine-proton}"
exec /opt/proton-ge/current/files/bin/wine "$@"
EOF
    chmod +x /usr/local/bin/proton-wine
    
    # Clean up
    rm -f /tmp/${PROTON_GE_VERSION}.tar.gz
    
    echo "Proton GE ${PROTON_GE_VERSION} installed successfully"
}

# Execute installation
install_proton_ge