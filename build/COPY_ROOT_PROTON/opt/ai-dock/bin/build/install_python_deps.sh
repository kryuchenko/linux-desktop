#!/bin/bash
# Install Python dependencies for Proton/Wine tools
# Uses virtual environment to avoid conflicts with AI/ML stack

set -e

function install_python_deps() {
    echo "Installing Python dependencies for Proton tools..."
    
    # Ensure python3-venv is installed
    apt-get install -y --no-install-recommends python3-venv
    
    # Create virtual environment for Proton tools
    python3 -m venv /opt/proton-tools
    
    # Activate virtual environment and install packages
    source /opt/proton-tools/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install gaming-related Python tools
    pip install --no-cache-dir \
        protontricks==1.12.0 \
        "websockets<14.0" \
        vdf \
        pyxdg
    
    # Deactivate virtual environment
    deactivate
    
    # Create system-wide wrapper for protontricks
    cat > /usr/local/bin/protontricks << 'EOF'
#!/bin/bash
source /opt/proton-tools/bin/activate
exec python3 -m protontricks "$@"
EOF
    chmod +x /usr/local/bin/protontricks
    
    # Create wrapper for other Python tools if needed
    cat > /usr/local/bin/proton-python << 'EOF'
#!/bin/bash
source /opt/proton-tools/bin/activate
exec python3 "$@"
EOF
    chmod +x /usr/local/bin/proton-python
    
    echo "Python dependencies installed successfully"
}

# Execute installation
install_python_deps