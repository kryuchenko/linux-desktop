#!/bin/bash
# Install Proton GE, gaming utilities and update Selkies-gstreamer on vastai/linux-desktop
# Usage: curl -fsSL https://gist.github.com/YOUR_GIST_URL/raw/install-proton-vastai.sh | bash

set -e

echo "============================================="
echo "Installing Proton GE and updating Selkies"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   exit 1
fi

# Update Selkies-gstreamer from 1.6.1 to 1.6.2 and fix websockets issue
print_status "Updating Selkies-gstreamer to version 1.6.2..."
SELKIES_VERSION="1.6.2"
SELKIES_VENV="/opt/ai-dock/environments/selkies"

# Check if running in the correct environment
if [ ! -d "/opt/ai-dock" ]; then
    print_error "This script is designed for vastai/linux-desktop containers with AI-Dock base!"
    print_error "Directory /opt/ai-dock not found."
    exit 1
fi

# Check current Selkies version
CURRENT_VERSION=$(grep -oP 'SELKIES_VERSION=\K[0-9.]+' /opt/ai-dock/etc/environment.sh 2>/dev/null || echo "unknown")
print_status "Current Selkies version: ${CURRENT_VERSION}"
print_status "Target Selkies version: ${SELKIES_VERSION}"

# Stop Selkies service if running
if command -v supervisorctl &> /dev/null; then
    print_status "Stopping Selkies service..."
    sudo supervisorctl stop selkies-gstreamer || true
fi

# Backup current Selkies installation
print_status "Backing up current Selkies installation..."
sudo cp -r /opt/gstreamer /opt/gstreamer.backup.$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
sudo cp -r /opt/selkies-gstreamer-web /opt/selkies-gstreamer-web.backup.$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# Download and install Selkies-gstreamer 1.6.2
cd /tmp
print_status "Downloading Selkies-gstreamer ${SELKIES_VERSION}..."
sudo curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/gstreamer-selkies_gpl_v${SELKIES_VERSION}_ubuntu$(lsb_release -rs)_$(dpkg --print-architecture).tar.gz" | sudo tar -xzf - -C /opt
sudo curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web_v${SELKIES_VERSION}.tar.gz" | sudo tar -xzf - -C /opt

# Update Selkies Python package
print_status "Updating Selkies Python package..."
curl -O -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl"
sudo "$SELKIES_VENV/bin/pip" install --no-cache-dir --force-reinstall "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl"
rm -f "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl"

# Fix websockets compatibility issue (critical for Python 3.10+)
print_status "Fixing websockets compatibility with Python 3.10+..."
sudo "$SELKIES_VENV/bin/pip" install --no-cache-dir --upgrade "websockets>=11,<12"

# Install missing audio processing library if needed
if ! dpkg -l | grep -q libwebrtc-audio-processing1; then
    print_status "Installing missing audio processing library..."
    sudo apt-get update
    sudo apt-get install -y libwebrtc-audio-processing1
fi

# Update Selkies JS interposer
print_status "Updating Selkies JS interposer..."
curl -o selkies-js-interposer.deb -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-js-interposer_v${SELKIES_VERSION}_ubuntu$(lsb_release -rs)_$(dpkg --print-architecture).deb"
sudo dpkg -i ./selkies-js-interposer.deb || sudo apt-get install -f -y
rm -f selkies-js-interposer.deb

# Update environment variable
sudo sed -i "s/SELKIES_VERSION=.*/SELKIES_VERSION=${SELKIES_VERSION}/g" /opt/ai-dock/etc/environment.sh 2>/dev/null || \
    sudo bash -c "echo 'SELKIES_VERSION=${SELKIES_VERSION}' >> /opt/ai-dock/etc/environment.sh"

# Clear GStreamer cache
print_status "Clearing GStreamer cache..."
rm -rf ~/.cache/gstreamer-1.0

# Restart Selkies service if it was running
if command -v supervisorctl &> /dev/null; then
    print_status "Starting Selkies service..."
    sudo supervisorctl start selkies-gstreamer || true
fi

print_status "Selkies-gstreamer updated to version ${SELKIES_VERSION} with websockets fix applied!"
print_warning "You may need to restart the container for all changes to take effect."

# Update package lists
print_status "Updating package lists..."
sudo apt-get update

# Install dependencies
print_status "Installing dependencies..."
sudo apt-get install -y \
    wget \
    curl \
    tar \
    zstd \
    wine \
    wine32 \
    wine64 \
    libwine \
    libwine:i386 \
    fonts-wine \
    zenity \
    cabextract \
    p7zip-full \
    gamemode \
    mangohud \
    vkbasalt \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386 \
    libvulkan1 \
    libvulkan1:i386 \
    vulkan-tools

# Create necessary directories
print_status "Creating directories..."
mkdir -p ~/.steam/steam/compatibilitytools.d
mkdir -p ~/.local/share/applications
mkdir -p ~/Games

# Install Proton GE
print_status "Downloading and installing Proton GE..."
PROTON_GE_VERSION=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep -Po '"tag_name": "\K[^"]*')
print_status "Latest Proton GE version: $PROTON_GE_VERSION"

cd /tmp
wget -q --show-progress "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_GE_VERSION}/${PROTON_GE_VERSION}.tar.gz"
tar -xf "${PROTON_GE_VERSION}.tar.gz" -C ~/.steam/steam/compatibilitytools.d/
rm -f "${PROTON_GE_VERSION}.tar.gz"

# Install winetricks
print_status "Installing winetricks..."
sudo wget -q -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
sudo chmod +x /usr/local/bin/winetricks

# Install Lutris dependencies
print_status "Installing Lutris dependencies..."
sudo apt-get install -y \
    python3 \
    python3-gi \
    python3-gi-cairo \
    python3-yaml \
    python3-requests \
    python3-pil \
    python3-setproctitle \
    python3-distro \
    python3-evdev \
    gir1.2-gtk-3.0 \
    gir1.2-webkit2-4.0 \
    psmisc \
    cabextract \
    unzip \
    p7zip \
    fluid-soundfont-gs

# Install Lutris
print_status "Installing Lutris..."
sudo add-apt-repository -y ppa:lutris-team/lutris
sudo apt-get update
sudo apt-get install -y lutris

# Install Steam (if not already installed)
if ! command -v steam &> /dev/null; then
    print_status "Installing Steam..."
    sudo dpkg --add-architecture i386
    sudo apt-get update
    sudo apt-get install -y steam-installer
fi

# Create desktop entries for Proton
print_status "Creating desktop entries..."

# Create Proton run script
cat > ~/.local/bin/proton-run << 'EOF'
#!/bin/bash
# Run Windows executables with Proton GE

PROTON_DIR="$HOME/.steam/steam/compatibilitytools.d"
PROTON_VERSION=$(ls -1 "$PROTON_DIR" | grep -E "^GE-Proton" | sort -V | tail -n1)

if [ -z "$PROTON_VERSION" ]; then
    zenity --error --text="Proton GE not found! Please install it first."
    exit 1
fi

export STEAM_COMPAT_DATA_PATH="$HOME/Games/proton-prefixes/default"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam"
mkdir -p "$STEAM_COMPAT_DATA_PATH"

"$PROTON_DIR/$PROTON_VERSION/proton" run "$@"
EOF

chmod +x ~/.local/bin/proton-run

# Create desktop file for Proton
cat > ~/.local/share/applications/proton-run.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Run with Proton
Comment=Run Windows executables with Proton GE
Exec=/home/user/.local/bin/proton-run %f
Icon=wine
Categories=Game;
MimeType=application/x-wine-extension-msp;application/x-msi;application/x-ms-dos-executable;application/x-msdos-program;application/x-msdownload;application/x-exe;application/x-winexe;application/x-dosexec;
NoDisplay=true
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications/

# Create a helper script for managing Proton prefixes
cat > ~/.local/bin/proton-manager << 'EOF'
#!/bin/bash
# Proton prefix manager

PREFIXES_DIR="$HOME/Games/proton-prefixes"
mkdir -p "$PREFIXES_DIR"

case "$1" in
    create)
        if [ -z "$2" ]; then
            echo "Usage: proton-manager create <prefix-name>"
            exit 1
        fi
        mkdir -p "$PREFIXES_DIR/$2"
        echo "Created prefix: $2"
        ;;
    list)
        echo "Available prefixes:"
        ls -1 "$PREFIXES_DIR"
        ;;
    delete)
        if [ -z "$2" ]; then
            echo "Usage: proton-manager delete <prefix-name>"
            exit 1
        fi
        rm -rf "$PREFIXES_DIR/$2"
        echo "Deleted prefix: $2"
        ;;
    *)
        echo "Usage: proton-manager {create|list|delete} [prefix-name]"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/proton-manager

# Install VKD3D-Proton
print_status "Installing VKD3D-Proton..."
VKD3D_VERSION=$(curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | grep -Po '"tag_name": "\K[^"]*')
cd /tmp
wget -q --show-progress "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/${VKD3D_VERSION}/vkd3d-proton-${VKD3D_VERSION}.tar.zst"
tar -I zstd -xf "vkd3d-proton-${VKD3D_VERSION}.tar.zst"
sudo cp -r "vkd3d-proton-${VKD3D_VERSION}"/x64/* /usr/lib/x86_64-linux-gnu/wine/
sudo cp -r "vkd3d-proton-${VKD3D_VERSION}"/x86/* /usr/lib/i386-linux-gnu/wine/
rm -rf "vkd3d-proton-${VKD3D_VERSION}"*

# Install DXVK
print_status "Installing DXVK..."
DXVK_VERSION=$(curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | grep -Po '"tag_name": "\K[^"]*')
wget -q --show-progress "https://github.com/doitsujin/dxvk/releases/download/${DXVK_VERSION}/dxvk-${DXVK_VERSION#v}.tar.gz"
tar -xf "dxvk-${DXVK_VERSION#v}.tar.gz"
sudo cp -r "dxvk-${DXVK_VERSION#v}"/x64/* /usr/lib/x86_64-linux-gnu/wine/
sudo cp -r "dxvk-${DXVK_VERSION#v}"/x32/* /usr/lib/i386-linux-gnu/wine/
rm -rf "dxvk-${DXVK_VERSION#v}"*

# Set up environment variables
print_status "Setting up environment variables..."
cat >> ~/.bashrc << 'EOF'

# Proton and Wine environment variables
export WINEPREFIX="$HOME/.wine"
export WINEARCH=win64
export PATH="$HOME/.local/bin:$PATH"

# Enable GameMode by default
export GAMEMODERUNEXEC="gamemoderun"

# MangoHud configuration
export MANGOHUD=1
export MANGOHUD_DLSYM=1
EOF

# Create MangoHud config
mkdir -p ~/.config/MangoHud
cat > ~/.config/MangoHud/MangoHud.conf << 'EOF'
# MangoHud configuration
fps_limit=0
vsync=0
gl_vsync=0
cpu_stats
cpu_temp
gpu_stats
gpu_temp
ram
vram
frame_timing
position=top-left
font_size=24
background_alpha=0.5
EOF

# Final setup
print_status "Running final setup..."

# Initialize wine prefix
DISPLAY=:0 wineboot --init

# Install common Windows libraries
print_status "Installing common Windows libraries with winetricks..."
DISPLAY=:0 winetricks -q corefonts vcrun2019 dotnet48

print_status "========================================="
print_status "Installation complete!"
print_status ""
print_status "Proton GE installed to: ~/.steam/steam/compatibilitytools.d/"
print_status ""
print_status "Usage:"
print_status "  - Right-click any .exe file and select 'Run with Proton'"
print_status "  - Use 'proton-run <exe-file>' from terminal"
print_status "  - Use 'proton-manager' to manage Wine prefixes"
print_status "  - Launch Lutris for managing games"
print_status ""
print_status "Restart your desktop session for all changes to take effect."
print_status "========================================="