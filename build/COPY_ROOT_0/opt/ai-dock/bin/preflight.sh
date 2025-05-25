#!/bin/bash

# This runs at container startup before services start

echo "=== Preflight checks and fixes ==="

# Fix user permissions that might be wrong after container creation
if id -u user >/dev/null 2>&1; then
    echo "Fixing user directory permissions..."
    
    # Ensure user owns their home directory
    chown -R user:ai-dock /home/user
    
    # Fix specific KDE/Plasma directories
    mkdir -p /home/user/.config
    mkdir -p /home/user/.config/plasma-org.kde.plasma.desktop-appletsrc.d
    mkdir -p /home/user/.local/share
    mkdir -p /home/user/.kde/share/config
    mkdir -p /home/user/.cache
    mkdir -p /home/user/Desktop
    
    # Fix ownership
    chown -R user:ai-dock /home/user/.config
    chown -R user:ai-dock /home/user/.local
    chown -R user:ai-dock /home/user/.kde
    chown -R user:ai-dock /home/user/.cache
    chown -R user:ai-dock /home/user/Desktop
    
    # Ensure config files are writable
    touch /home/user/.config/startplasma-x11rc
    chown user:ai-dock /home/user/.config/startplasma-x11rc
    chmod 644 /home/user/.config/startplasma-x11rc
    
    # Fix other KDE config files
    touch /home/user/.config/kdesktoprc
    chown user:ai-dock /home/user/.config/kdesktoprc
    chmod 644 /home/user/.config/kdesktoprc
    
    echo "User directory permissions fixed"
else
    echo "WARNING: User 'user' not found!"
fi

# Move DirectX debugger from root to user if needed
if [ -f /root/Desktop/directx-args-debugger.exe ] && [ ! -f /home/user/Desktop/directx-args-debugger.exe ]; then
    echo "Moving DirectX debugger to user desktop..."
    mv /root/Desktop/directx-* /home/user/Desktop/ 2>/dev/null || true
    chown -R user:ai-dock /home/user/Desktop/
fi

# Ensure NVIDIA environment variables are set
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
export __VK_LAYER_NV_optimus=NVIDIA_only

# Ensure USER_NAME is set correctly
if [ -z "$USER_NAME" ] || [ "$USER_NAME" = "root" ]; then
    export USER_NAME="user"
    echo "Set USER_NAME to: $USER_NAME"
fi

# Create .xinitrc for X session
if [ ! -f /home/user/.xinitrc ]; then
    cat > /home/user/.xinitrc << 'EOF'
#!/bin/bash
export DESKTOP_SESSION=plasma
export XDG_SESSION_DESKTOP=KDE
export XDG_CURRENT_DESKTOP=KDE
exec startplasma-x11
EOF
    chmod +x /home/user/.xinitrc
    chown user:ai-dock /home/user/.xinitrc
fi

echo "=== Preflight complete ==="