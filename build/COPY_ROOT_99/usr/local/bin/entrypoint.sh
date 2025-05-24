#!/bin/bash
# Entrypoint script for Vast.ai compatibility
# This script sets up port forwarding and then calls the main init

set -e

# Setup port forwarding for Vast.ai if needed
if [ -n "$PUBLIC_KEY" ]; then
    mkdir -p ~/.ssh
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
fi

# Handle Vast.ai specific environment
if [ -n "$VAST_CONTAINERLABEL" ]; then
    echo "Running in Vast.ai environment"
    
    # Setup port forwarding if configured
    if [ -f "/etc/ssh/sshd_config" ]; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        service ssh start || true
    fi
fi

# Execute the main init script
exec /opt/ai-dock/bin/init.sh "$@"