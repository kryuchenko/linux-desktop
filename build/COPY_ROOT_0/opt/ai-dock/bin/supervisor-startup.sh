#!/bin/bash

# This runs when supervisor starts, before any services

echo "Running startup permission fixes..."

# Run preflight checks
if [ -x /opt/ai-dock/bin/preflight.sh ]; then
    /opt/ai-dock/bin/preflight.sh
fi

# Additional KDE-specific fixes
if [ -d /home/user ]; then
    # Ensure KDE can write its config
    find /home/user/.config -type f -name "*.rc" -exec chmod 644 {} \; 2>/dev/null || true
    find /home/user/.config -type d -exec chmod 755 {} \; 2>/dev/null || true
    
    # Fix Plasma specific files
    for file in startplasma-x11rc startkderc plasma-localerc plasmarc kdeglobals; do
        if [ ! -f "/home/user/.config/$file" ]; then
            touch "/home/user/.config/$file"
        fi
        chown user:ai-dock "/home/user/.config/$file"
        chmod 644 "/home/user/.config/$file"
    done
fi

echo "Startup permission fixes complete"