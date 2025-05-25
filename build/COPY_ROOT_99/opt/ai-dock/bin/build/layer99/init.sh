#!/bin/bash
set -eo pipefail
umask 002
# Override this file to add extras to your build
# Wine, Winetricks, Lutris, this process must be consistent with https://wiki.winehq.org/Ubuntu

mkdir -pm755 /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/winehq-archive.key "https://dl.winehq.org/wine-builds/winehq.key"
curl -fsSL -o "/etc/apt/sources.list.d/winehq-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').sources" "https://dl.winehq.org/wine-builds/ubuntu/dists/$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"')/winehq-$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"').sources"

# Try to update apt, but continue if Wine repo fails
set +e
apt-get update
set -e

# Install Wine, retry if needed
WINE_INSTALLED=false
for i in {1..3}; do
    if apt-get install --install-recommends -y winehq-${WINE_BRANCH}; then
        WINE_INSTALLED=true
        break
    else
        echo "Wine installation attempt $i failed, retrying..."
        sleep 5
        set +e
        apt-get update
        set -e
    fi
done

# Fallback to Ubuntu's wine if WineHQ fails
if [ "$WINE_INSTALLED" = false ]; then
    echo "WineHQ installation failed, falling back to Ubuntu wine packages..."
    apt-get install --install-recommends -y wine wine64 wine32:i386
fi

export LUTRIS_VERSION="$(curl -fsSL "https://api.github.com/repos/lutris/lutris/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')"
env-store LUTRIS_VERSION
curl -fsSL -O "https://github.com/lutris/lutris/releases/download/v${LUTRIS_VERSION}/lutris_${LUTRIS_VERSION}_all.deb"
apt-get install --no-install-recommends -y ./lutris_${LUTRIS_VERSION}_all.deb && rm -f "./lutris_${LUTRIS_VERSION}_all.deb"
curl -fsSL -o /usr/bin/winetricks "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
chmod 755 /usr/bin/winetricks
curl -fsSL -o /usr/share/bash-completion/completions/winetricks "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion"
ln -sf /usr/games/lutris /usr/bin/lutris

# Proton GE 10-3
echo "Installing Proton GE 10-3..."
mkdir -p /opt/proton-ge
cd /opt/proton-ge
PROTON_GE_VERSION="GE-Proton10-3"
echo "Downloading Proton GE version: ${PROTON_GE_VERSION}"
curl -fsSL -o proton-ge.tar.gz "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_GE_VERSION}/${PROTON_GE_VERSION}.tar.gz"
tar -xzf proton-ge.tar.gz
rm proton-ge.tar.gz
# Create symlink for easy access
ln -sf /opt/proton-ge/${PROTON_GE_VERSION} /opt/proton-ge/current
# Add to PATH via wrapper script
cat > /opt/ai-dock/bin/proton-ge <<'EOF'
#!/bin/bash
export PROTON_GE_HOME="/opt/proton-ge/current"
export PATH="${PROTON_GE_HOME}:${PATH}"
exec "${PROTON_GE_HOME}/proton" "$@"
EOF
chmod +x /opt/ai-dock/bin/proton-ge

# Install Steam
echo "Installing Steam..."
# Add multiverse repository for Steam
add-apt-repository multiverse -y
dpkg --add-architecture i386
set +e
apt-get update
set -e

# Install Steam and dependencies
apt-get install --no-install-recommends -y \
    steam-installer \
    libgl1-mesa-dri:amd64 \
    libgl1-mesa-dri:i386 \
    libgl1-mesa-glx:amd64 \
    libgl1-mesa-glx:i386 \
    libc6:i386

# Install Protontricks and performance-critical gaming components
echo "Installing Protontricks and gaming performance tools..."

apt-get install --no-install-recommends -y \
    python3-pip \
    python3-setuptools \
    python3-venv \
    zenity \
    gamemode \
    mangohud \
    vulkan-tools \
    mesa-vulkan-drivers \
    libvulkan1 \
    libvulkan1:i386 \
    libgl1-mesa-glx:i386 \
    libgl1-mesa-dri:i386

# Install protontricks in system Python (needed for global access)
# For Ubuntu 22.04, we need to use different approach
export PIP_BREAK_SYSTEM_PACKAGES=1
pip3 install protontricks

# Configure GameMode for auto-optimization
cat > /etc/gamemode.ini <<'EOF'
[general]
renice = 10
inhibit_screensaver = 1

[gpu]
apply_gpu_optimisations = accept-responsibility
gpu_device = 0
amd_performance_level = high
nv_powermizer_mode = 1
EOF

# Create symlink for gamemoderun if it's in /usr/games
if [ -f /usr/games/gamemoderun ]; then
    ln -sf /usr/games/gamemoderun /usr/local/bin/gamemoderun
fi
# Create wrapper for Protontricks to work with Steam and our Proton GE
cat > /opt/ai-dock/bin/protontricks <<'EOF'
#!/bin/bash
# Protontricks wrapper that works with Steam
# First time Steam needs to be run to create directories
if [ ! -d "$HOME/.steam" ]; then
    echo "First time setup: Initializing Steam directories..."
    steam -silent &
    STEAM_PID=$!
    sleep 10
    kill $STEAM_PID 2>/dev/null || true
fi

# Set up Proton GE in Steam's compatibility tools
COMPAT_TOOLS_DIR="$HOME/.steam/root/compatibilitytools.d"
mkdir -p "$COMPAT_TOOLS_DIR"
if [ ! -L "$COMPAT_TOOLS_DIR/GE-Proton10-3" ]; then
    ln -sf /opt/proton-ge/GE-Proton10-3 "$COMPAT_TOOLS_DIR/GE-Proton10-3"
fi

exec /usr/local/bin/protontricks "$@"
EOF
chmod +x /opt/ai-dock/bin/protontricks

# Create wrapper script for running exe files with Proton
cat > /opt/ai-dock/bin/proton-run <<'EOF'
#!/bin/bash
# Wrapper script to run exe files with Proton GE

EXE_PATH="$1"
if [ -z "$EXE_PATH" ]; then
    echo "Usage: proton-run <path-to-exe>"
    exit 1
fi

# Get absolute path
EXE_PATH=$(realpath "$EXE_PATH")
EXE_DIR=$(dirname "$EXE_PATH")
EXE_NAME=$(basename "$EXE_PATH")

# Set up Proton environment
export STEAM_COMPAT_CLIENT_INSTALL_PATH="/opt/proton-ge/current"
# Ensure we use the correct home directory for the current user
if [ "$USER" = "root" ]; then
    PROTON_PREFIX_DIR="/root/.proton-ge-prefixes"
else
    PROTON_PREFIX_DIR="${HOME:-/home/$USER}/.proton-ge-prefixes"
fi
export STEAM_COMPAT_DATA_PATH="$PROTON_PREFIX_DIR/$(echo "$EXE_PATH" | md5sum | cut -d' ' -f1)"
export PROTON_USE_WINED3D=0
export PROTON_NO_ESYNC=0
export PROTON_NO_FSYNC=0

# Create prefix directory if it doesn't exist
mkdir -p "$STEAM_COMPAT_DATA_PATH"

# Change to exe directory for proper relative path handling
cd "$EXE_DIR"

# Run with Proton and GameMode for better performance
# Check if gamemoderun is available in PATH, otherwise use direct path
if command -v gamemoderun >/dev/null 2>&1; then
    exec gamemoderun /opt/proton-ge/current/proton run "$EXE_NAME" "${@:2}"
elif [ -x /usr/games/gamemoderun ]; then
    exec /usr/games/gamemoderun /opt/proton-ge/current/proton run "$EXE_NAME" "${@:2}"
else
    echo "Warning: gamemoderun not found, running without GameMode optimization"
    exec /opt/proton-ge/current/proton run "$EXE_NAME" "${@:2}"
fi
EOF
chmod +x /opt/ai-dock/bin/proton-run

# Create desktop entry for exe files
mkdir -p /usr/share/applications
cat > /usr/share/applications/proton-run.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Run with Proton GE
Exec=/opt/ai-dock/bin/proton-run %f
MimeType=application/x-wine-extension-msp;application/x-msi;application/x-ms-dos-executable;application/x-msdos-program;application/x-msdownload;application/x-exe;application/x-winexe;application/x-dosexec;
NoDisplay=true
StartupNotify=false
Terminal=false
Icon=wine
EOF

# Update MIME database to associate exe files
cat > /usr/share/mime/packages/proton-exe.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-wine-extension-msp">
    <glob pattern="*.msp"/>
  </mime-type>
  <mime-type type="application/x-msi">
    <glob pattern="*.msi"/>
  </mime-type>
  <mime-type type="application/x-ms-dos-executable">
    <glob pattern="*.exe"/>
  </mime-type>
  <mime-type type="application/x-msdos-program">
    <glob pattern="*.exe"/>
  </mime-type>
  <mime-type type="application/x-msdownload">
    <glob pattern="*.exe"/>
  </mime-type>
  <mime-type type="application/x-exe">
    <glob pattern="*.exe"/>
  </mime-type>
  <mime-type type="application/x-winexe">
    <glob pattern="*.exe"/>
  </mime-type>
  <mime-type type="application/x-dosexec">
    <glob pattern="*.exe"/>
  </mime-type>
</mime-info>
EOF

# Set as default handler for exe files
mkdir -p /usr/share/applications
update-mime-database /usr/share/mime
xdg-mime default proton-run.desktop application/x-ms-dos-executable
xdg-mime default proton-run.desktop application/x-msdos-program
xdg-mime default proton-run.desktop application/x-msdownload
xdg-mime default proton-run.desktop application/x-exe
xdg-mime default proton-run.desktop application/x-winexe
xdg-mime default proton-run.desktop application/x-dosexec

# Create KDE-specific mime associations for user
mkdir -p /home/user/.config
# Create required KDE startup file to prevent "not writable" error
touch /home/user/.config/startplasma-x11rc
cat > /home/user/.config/mimeapps.list <<'EOF'
[Default Applications]
application/x-ms-dos-executable=proton-run.desktop
application/x-msdos-program=proton-run.desktop
application/x-msdownload=proton-run.desktop
application/x-exe=proton-run.desktop
application/x-winexe=proton-run.desktop
application/x-dosexec=proton-run.desktop
application/x-wine-extension-msp=proton-run.desktop

[Added Associations]
application/x-ms-dos-executable=proton-run.desktop;
application/x-msdos-program=proton-run.desktop;
application/x-msdownload=proton-run.desktop;
application/x-exe=proton-run.desktop;
application/x-winexe=proton-run.desktop;
application/x-dosexec=proton-run.desktop;
application/x-wine-extension-msp=proton-run.desktop;
EOF

# Create KDE service menu for right-click context
mkdir -p /usr/share/kservices5/ServiceMenus
cat > /usr/share/kservices5/ServiceMenus/proton-run.desktop <<'EOF'
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-ms-dos-executable;application/x-msdos-program;application/x-msdownload;application/x-exe;application/x-winexe;application/x-dosexec;
Actions=RunWithProton;

[Desktop Action RunWithProton]
Name=Run with Proton
Icon=wine
Exec=/opt/ai-dock/bin/proton-run %f
EOF

# Create additional KDE directories and files to prevent startup issues
mkdir -p /home/user/.local/share/kwalletd
mkdir -p /home/user/.kde/share/config
mkdir -p /home/user/.cache/plasma
# Ensure .config directory structure exists
mkdir -p /home/user/.config/kde.org
mkdir -p /home/user/.config/plasma-workspace

# Ownership will be fixed by fix-permissions.sh later

cd /

# Libre Office

apt-get install --install-recommends -y \
        libreoffice \
        libreoffice-kf5 \
        libreoffice-plasma \
        libreoffice-style-breeze

# Graphics utils
set +e
apt-get update
set -e
$APT_INSTALL \
    gimp \
    inkscape

cd /opt
wget https://ftp.halifax.rwth-aachen.de/blender/release/Blender4.2/blender-4.2.0-linux-x64.tar.xz
tar xvf blender-4.2.0-linux-x64.tar.xz
rm blender-4.2.0-linux-x64.tar.xz
ln -s /opt/blender-4.2.0-linux-x64/blender /opt/ai-dock/bin/blender
cp /opt/blender-4.2.0-linux-x64/blender.desktop /usr/share/applications
cp /opt/blender-4.2.0-linux-x64/blender.svg /usr/share/icons/hicolor/scalable/apps/


mkdir -p /opt/krita
wget -O /opt/krita/krita.appimage https://download.kde.org/stable/krita/5.2.3/krita-5.2.3-x86_64.appimage
chmod +x /opt/krita/krita.appimage
(cd /opt/krita && /opt/krita/krita.appimage --appimage-extract)
rm -f /opt/krita/krita.appimage
cp -rf /opt/krita/squashfs-root/usr/share/{applications,icons} /usr/share/
chmod +x /opt/ai-dock/bin/krita

# Chrome
wget -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
$APT_INSTALL /tmp/chrome.deb
dpkg-divert --add /opt/google/chrome/google-chrome
cp -f /opt/google/chrome/google-chrome /opt/google/chrome/google-chrome.distrib
cp -f /opt/ai-dock/share/google-chrome/bin/google-chrome /opt/google/chrome/google-chrome

apt-get clean -y

# Download DirectX Args Debugger to Desktop for testing
echo "Setting up DirectX test application..."
# Use /root during build, will be moved to user home later
mkdir -p /root/Desktop
cd /root/Desktop
wget -q https://github.com/kryuchenko/directx-args-debugger/raw/main/build/directx-args-debugger.exe
chmod +x directx-args-debugger.exe

# Create desktop launcher
cat > /root/Desktop/directx-debugger.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=DirectX Args Debugger
Comment=Test DirectX arguments with Proton
Exec=/opt/ai-dock/bin/proton-run /root/Desktop/directx-args-debugger.exe
Icon=wine
Terminal=true
Categories=Game;
StartupNotify=true
EOF
chmod +x /root/Desktop/directx-debugger.desktop

# Mark desktop files as trusted for KDE Plasma 5
# This prevents "for security reasons" error when clicking executables
gio set /root/Desktop/directx-debugger.desktop metadata::trusted true 2>/dev/null || true
gio set /root/Desktop/directx-args-debugger.exe metadata::trusted true 2>/dev/null || true

# Create KDE config to allow desktop executables
mkdir -p /root/.config/plasma-org.kde.plasma.desktop-appletsrc.d/
cat > /root/.config/kdesktoprc <<'EOF'
[Desktop Settings]
AllowDesktopExecutables=true
EOF

# Fix ownership for user directories before fix-permissions.sh
# Only run if user exists (not during build)
if id -u user >/dev/null 2>&1; then
    chown -R user:ai-dock /home/user/.config || true
    chown -R user:ai-dock /home/user/.local || true
    chown -R user:ai-dock /home/user/.kde || true
    chown -R user:ai-dock /home/user/Desktop || true
fi

# Ownership will be fixed by fix-permissions.sh later

# Set NVIDIA environment variables for GPU acceleration
cat > /etc/profile.d/nvidia-gpu.sh << 'EOF'
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
export __VK_LAYER_NV_optimus=NVIDIA_only
EOF
chmod +x /etc/profile.d/nvidia-gpu.sh

fix-permissions.sh -o container

# Create entrypoint.sh symlink for vast.ai compatibility
ln -sf /opt/ai-dock/bin/init.sh /usr/local/bin/entrypoint.sh
chmod +x /usr/local/bin/entrypoint.sh

rm -rf /tmp/*

rm /etc/ld.so.cache
ldconfig
