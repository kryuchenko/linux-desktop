#!/bin/bash
# Initialize Proton GE environment
# Sets up environment variables and creates necessary directories

set -e

# Source environment if available
[[ -f /opt/ai-dock/etc/environment.sh ]] && source /opt/ai-dock/etc/environment.sh

# Setup Proton environment variables
export PROTON_DIR="/opt/proton-ge/current"
export PATH="${PROTON_DIR}/files/bin:${PATH}"
export WINE="${PROTON_DIR}/files/bin/wine"
export WINEPREFIX="${WINEPREFIX:-${WORKSPACE}/.wine}"
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
export WINEARCH="win64"

# Setup Vulkan ICD paths for multi-vendor support
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/radeon_icd.x86_64.json:/usr/share/vulkan/icd.d/intel_icd.x86_64.json"
export VK_LAYER_PATH="/usr/share/vulkan/explicit_layer.d:/usr/share/vulkan/implicit_layer.d"

# Proton specific settings
export PROTON_USE_WINED3D11=0
export PROTON_NO_ESYNC=0
export PROTON_NO_FSYNC=0
export PROTON_HIDE_NVIDIA_GPU=0
export PROTON_ENABLE_NVAPI=1

# MangoHud configuration
export MANGOHUD_CONFIG="cpu_temp,gpu_temp,ram,vram,frametime,position=top-right"
export MANGOHUD_CONFIGFILE="/etc/mangohud/MangoHud.conf"

# Create necessary directories
mkdir -p "${WORKSPACE}/.wine"
mkdir -p "${WORKSPACE}/.proton"
mkdir -p "${WORKSPACE}/.local/share/Steam/compatibilitytools.d"
mkdir -p "${WORKSPACE}/.config/MangoHud"

# Link Proton GE to user's Steam directory if needed
if [ ! -e "${WORKSPACE}/.local/share/Steam/compatibilitytools.d/GE-Proton10-3" ]; then
    ln -sf /opt/steam/compatibilitytools.d/GE-Proton10-3 "${WORKSPACE}/.local/share/Steam/compatibilitytools.d/"
fi

# Copy MangoHud config to user directory if not exists
if [ ! -f "${WORKSPACE}/.config/MangoHud/MangoHud.conf" ]; then
    cp /etc/mangohud/MangoHud.conf "${WORKSPACE}/.config/MangoHud/"
fi

# Initialize wine prefix if it doesn't exist
if [ ! -f "${WINEPREFIX}/system.reg" ]; then
    echo "Initializing Wine prefix at ${WINEPREFIX}..."
    ${WINE} wineboot -u
fi

# Set proper permissions
chown -R ${WORKSPACE_USER}:${WORKSPACE_USER} "${WORKSPACE}/.wine" 2>/dev/null || true
chown -R ${WORKSPACE_USER}:${WORKSPACE_USER} "${WORKSPACE}/.proton" 2>/dev/null || true
chown -R ${WORKSPACE_USER}:${WORKSPACE_USER} "${WORKSPACE}/.local" 2>/dev/null || true
chown -R ${WORKSPACE_USER}:${WORKSPACE_USER} "${WORKSPACE}/.config" 2>/dev/null || true

# Write environment to file for other processes
cat > /opt/ai-dock/etc/proton.env << EOF
export PROTON_DIR="${PROTON_DIR}"
export PATH="${PROTON_DIR}/files/bin:\${PATH}"
export WINE="${WINE}"
export WINEPREFIX="${WINEPREFIX}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES}"
export WINEARCH="${WINEARCH}"
export VK_ICD_FILENAMES="${VK_ICD_FILENAMES}"
export VK_LAYER_PATH="${VK_LAYER_PATH}"
export PROTON_USE_WINED3D11=${PROTON_USE_WINED3D11}
export PROTON_NO_ESYNC=${PROTON_NO_ESYNC}
export PROTON_NO_FSYNC=${PROTON_NO_FSYNC}
export PROTON_HIDE_NVIDIA_GPU=${PROTON_HIDE_NVIDIA_GPU}
export PROTON_ENABLE_NVAPI=${PROTON_ENABLE_NVAPI}
export MANGOHUD_CONFIG="${MANGOHUD_CONFIG}"
export MANGOHUD_CONFIGFILE="${MANGOHUD_CONFIGFILE}"
EOF

echo "Proton GE environment initialized successfully"
echo "Wine prefix: ${WINEPREFIX}"
echo "Proton version: $(${PROTON_DIR}/proton --version 2>/dev/null || echo 'GE-Proton10-3')"