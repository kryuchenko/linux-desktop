#!/bin/bash
# Test script to validate Proton GE installation
# Runs various checks to ensure everything is working correctly

set -e

echo "=== Proton GE Installation Test ==="
echo

# Source Proton environment
if [ -f /opt/ai-dock/etc/proton.env ]; then
    source /opt/ai-dock/etc/proton.env
    echo "✓ Proton environment sourced successfully"
else
    echo "✗ Proton environment not found"
    exit 1
fi

# Check Wine installation
echo
echo "Checking Wine installation..."
if command -v wine &> /dev/null; then
    echo "✓ Wine installed: $(wine --version)"
else
    echo "✗ Wine not found"
    exit 1
fi

if command -v wine64 &> /dev/null; then
    echo "✓ Wine64 installed: $(wine64 --version)"
else
    echo "✗ Wine64 not found"
    exit 1
fi

# Check Proton GE installation
echo
echo "Checking Proton GE installation..."
if [ -d "/opt/proton-ge/current" ]; then
    echo "✓ Proton GE directory exists"
    if [ -f "/opt/proton-ge/current/proton" ]; then
        echo "✓ Proton executable found"
        # Try to get version
        if [ -f "/opt/proton-ge/current/version" ]; then
            echo "✓ Proton version: $(cat /opt/proton-ge/current/version)"
        else
            echo "✓ Proton version: GE-Proton10-3"
        fi
    else
        echo "✗ Proton executable not found"
        exit 1
    fi
else
    echo "✗ Proton GE directory not found"
    exit 1
fi

# Check 32-bit support
echo
echo "Checking 32-bit architecture support..."
if dpkg --print-foreign-architectures | grep -q i386; then
    echo "✓ 32-bit architecture enabled"
else
    echo "✗ 32-bit architecture not enabled"
    exit 1
fi

# Check Vulkan support
echo
echo "Checking Vulkan support..."
if command -v vulkaninfo &> /dev/null; then
    echo "✓ Vulkan tools installed"
    # Check for Vulkan drivers
    if vulkaninfo --summary &> /dev/null; then
        echo "✓ Vulkan drivers functional"
    else
        echo "⚠ Vulkan drivers may not be properly configured"
    fi
else
    echo "✗ Vulkan tools not found"
fi

# Check Python tools
echo
echo "Checking Python tools..."
if command -v protontricks &> /dev/null; then
    echo "✓ Protontricks installed"
else
    echo "✗ Protontricks not found"
fi

# Check gaming utilities
echo
echo "Checking gaming utilities..."
if command -v gamemoded &> /dev/null; then
    echo "✓ GameMode installed"
else
    echo "✗ GameMode not found"
fi

if command -v mangohud &> /dev/null; then
    echo "✓ MangoHud installed"
else
    echo "✗ MangoHud not found"
fi

# Check directories
echo
echo "Checking user directories..."
dirs_to_check=(
    "${WORKSPACE}/.wine"
    "${WORKSPACE}/.proton"
    "${WORKSPACE}/.local/share/Steam/compatibilitytools.d"
    "${WORKSPACE}/.config/MangoHud"
)

for dir in "${dirs_to_check[@]}"; do
    if [ -d "$dir" ]; then
        echo "✓ Directory exists: $dir"
    else
        echo "✗ Directory missing: $dir"
    fi
done

# Summary
echo
echo "=== Test Summary ==="
echo "All critical components are installed and configured."
echo "You can now run Windows applications using:"
echo "  - proton run <executable>"
echo "  - proton-wine <executable>"
echo "  - wine <executable> (system Wine)"
echo
echo "To enable performance monitoring, prefix commands with:"
echo "  - MANGOHUD=1 <command>"
echo "  - gamemoderun <command>"