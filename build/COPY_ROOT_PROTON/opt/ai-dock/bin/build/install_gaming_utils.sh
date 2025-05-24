#!/bin/bash
# Install additional gaming utilities
# GameMode, MangoHud, and other tools for optimal gaming experience

set -e

function install_gaming_utils() {
    echo "Installing gaming utilities..."
    
    # Add required PPAs for latest versions
    add-apt-repository -y ppa:oibaf/graphics-drivers || true
    apt-get update
    
    # Install GameMode for performance optimization
    apt-get install -y --no-install-recommends \
        gamemode \
        gamemode-daemon \
        libgamemode0 \
        libgamemodeauto0
    
    # Install MangoHud for performance monitoring
    apt-get install -y --no-install-recommends \
        mangohud \
        mangohud:i386
    
    # Install additional utilities
    apt-get install -y --no-install-recommends \
        cabextract \
        unzip \
        p7zip-full \
        dos2unix \
        zenity \
        xdotool \
        yad
    
    # Install media codecs for cutscenes
    apt-get install -y --no-install-recommends \
        ffmpeg \
        gstreamer1.0-libav \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-vaapi
    
    # Create MangoHud config directory
    mkdir -p /etc/mangohud
    
    # Create default MangoHud configuration
    cat > /etc/mangohud/MangoHud.conf << 'EOF'
# Default MangoHud configuration for Proton GE
cpu_temp
gpu_temp
ram
vram
frametime
position=top-right
toggle_hud=F12
toggle_fps_limit=F11
fps_limit=0,60,144
font_size=24
no_display_battery
background_alpha=0.5
EOF
    
    # Create GameMode configuration
    mkdir -p /etc/gamemode.d
    cat > /etc/gamemode.d/gamemode.ini << 'EOF'
[general]
; GameMode configuration for optimal performance
reaper_freq=5
desiredgov=performance
igpu_desiredgov=performance
igpu_power_threshold=0.3
min_core_perf=0

[custom]
; Custom scripts can be added here
start=notify-send "GameMode started"
end=notify-send "GameMode stopped"

[gpu]
; GPU performance settings
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high
EOF
    
    echo "Gaming utilities installed successfully"
}

# Execute installation
install_gaming_utils