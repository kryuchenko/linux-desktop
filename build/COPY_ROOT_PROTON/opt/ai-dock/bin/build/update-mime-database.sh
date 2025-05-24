#!/bin/bash
# Update MIME database and desktop file associations
# This script should be run after Proton installation

set -e

function update_mime_associations() {
    echo "Updating MIME database and file associations..."
    
    # Update MIME database
    if command -v update-mime-database &> /dev/null; then
        update-mime-database /usr/share/mime
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database /usr/share/applications
    fi
    
    # Set default application for Windows executables
    if command -v xdg-mime &> /dev/null; then
        xdg-mime default proton-run.desktop application/x-wine-extension-msp
        xdg-mime default proton-run.desktop application/x-msi
        xdg-mime default proton-run.desktop application/x-msdos-program
        xdg-mime default proton-run.desktop application/x-msdownload
        xdg-mime default proton-run.desktop application/x-exe
        xdg-mime default proton-run.desktop application/x-bat
    fi
    
    # Update KDE file associations cache
    if command -v kbuildsycoca5 &> /dev/null; then
        kbuildsycoca5 --noincremental
    fi
    
    echo "MIME associations updated successfully"
}

# Execute update
update_mime_associations