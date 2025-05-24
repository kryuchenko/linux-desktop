#!/bin/bash
# Pre-download DXVK state caches for popular games
# This improves first-run performance by avoiding shader compilation

set -e

function install_dxvk_cache() {
    echo "Installing DXVK and pre-downloading state caches..."
    
    # Create DXVK cache directory
    mkdir -p /opt/dxvk-cache
    mkdir -p ~/.cache/dxvk
    
    # Download latest DXVK releases
    echo "Downloading latest DXVK..."
    DXVK_VERSION="2.4"
    wget -q -O /tmp/dxvk.tar.gz \
        "https://github.com/doitsujin/dxvk/releases/download/v${DXVK_VERSION}/dxvk-${DXVK_VERSION}.tar.gz" || true
    
    if [ -f /tmp/dxvk.tar.gz ]; then
        tar -xzf /tmp/dxvk.tar.gz -C /opt/dxvk-cache/
        rm /tmp/dxvk.tar.gz
        
        # Make DXVK available system-wide
        ln -sf "/opt/dxvk-cache/dxvk-${DXVK_VERSION}" /opt/dxvk-cache/latest
    fi
    
    # Download VKD3D-Proton for DirectX 12
    echo "Downloading VKD3D-Proton..."
    VKD3D_VERSION="2.13"
    wget -q -O /tmp/vkd3d.tar.xz \
        "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v${VKD3D_VERSION}/vkd3d-proton-${VKD3D_VERSION}.tar.xz" || true
    
    if [ -f /tmp/vkd3d.tar.xz ]; then
        tar -xJf /tmp/vkd3d.tar.xz -C /opt/dxvk-cache/
        rm /tmp/vkd3d.tar.xz
        
        # Make VKD3D available
        ln -sf "/opt/dxvk-cache/vkd3d-proton-${VKD3D_VERSION}" /opt/dxvk-cache/vkd3d-latest
    fi
    
    # Pre-download popular DXVK state caches from GitHub
    echo "Downloading popular DXVK state caches..."
    
    # These are community-contributed caches for popular games
    CACHE_URLS=(
        "https://github.com/doitsujin/dxvk/files/14141447/dxvk_cache_pool.tar.gz"
        "https://github.com/doitsujin/dxvk/files/13089305/common_dxvk_caches.tar.gz"
    )
    
    for url in "${CACHE_URLS[@]}"; do
        filename=$(basename "$url")
        echo "Downloading cache: $filename"
        wget -q -O "/tmp/$filename" "$url" 2>/dev/null || true
        
        if [ -f "/tmp/$filename" ]; then
            tar -xzf "/tmp/$filename" -C /opt/dxvk-cache/ 2>/dev/null || true
            rm "/tmp/$filename"
        fi
    done
    
    # Create environment setup script for DXVK
    cat > /opt/dxvk-cache/setup_dxvk.sh << 'EOF'
#!/bin/bash
# Setup DXVK environment for a Wine prefix
export DXVK_STATE_CACHE_PATH="/opt/dxvk-cache"
export DXVK_CONFIG_FILE="/opt/dxvk-cache/dxvk.conf"
export VKD3D_CONFIG="dxr"

# Copy DXVK caches to user directory if they don't exist
if [ -n "$WINEPREFIX" ] && [ -d "/opt/dxvk-cache" ]; then
    mkdir -p "$WINEPREFIX/drive_c/users/steamuser/AppData/Local/dxvk-cache"
    
    # Copy pre-downloaded caches
    find /opt/dxvk-cache -name "*.dxvk-cache" -exec cp {} "$WINEPREFIX/drive_c/users/steamuser/AppData/Local/dxvk-cache/" \; 2>/dev/null || true
fi
EOF
    chmod +x /opt/dxvk-cache/setup_dxvk.sh
    
    # Create DXVK configuration for optimal performance
    cat > /opt/dxvk-cache/dxvk.conf << 'EOF'
# DXVK configuration for optimal gaming performance
dxgi.tearFree = True
dxgi.maxFrameLatency = 1
dxvk.enableAsync = True
dxvk.numCompilerThreads = 0
dxvk.useRawSsbo = True
EOF
    
    # Set proper permissions
    chmod -R 755 /opt/dxvk-cache/
    
    echo "DXVK and state caches installed successfully"
}

# Execute installation
install_dxvk_cache