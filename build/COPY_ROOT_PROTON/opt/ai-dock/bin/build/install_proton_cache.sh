#!/bin/bash
# Pre-populate Proton caches and prefixes to avoid runtime downloads
# This includes DirectX, VCRedist, and common game dependencies

set -e

function install_proton_cache() {
    echo "Pre-populating Proton caches and dependencies..."
    
    # Set up temporary environment for cache population
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="/opt/steam"
    export STEAM_COMPAT_DATA_PATH="/tmp/proton_cache"
    export PROTON_DIR="/opt/proton-ge/current"
    export WINEPREFIX="/tmp/proton_wine_cache"
    export WINEDLLOVERRIDES="winemenubuilder.exe=d"
    
    # Create cache directories
    mkdir -p /opt/steam/steamapps/shadercache
    mkdir -p /opt/steam/config
    mkdir -p /opt/steam/logs
    mkdir -p "$STEAM_COMPAT_DATA_PATH"
    mkdir -p "$WINEPREFIX"
    
    # Download common DirectX and VCRedist installers that Proton uses
    echo "Downloading DirectX and Visual C++ redistributables..."
    
    # Create Proton's expected directories
    mkdir -p /opt/steam/steamapps/common/Proton
    mkdir -p /opt/steam/steamapps/common/SteamLinuxRuntime
    
    # Download common redistributables that games often need
    REDIST_DIR="/opt/steam/steamapps/redistributables"
    mkdir -p "$REDIST_DIR"
    
    # DirectX End-User Runtime
    echo "Downloading DirectX End-User Runtime..."
    wget -q -O "$REDIST_DIR/directx_Jun2010_redist.exe" \
        "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE4-8422-9F7DC6D9CBC5/directx_Jun2010_redist.exe" || true
    
    # Visual C++ 2019 Redistributable
    echo "Downloading Visual C++ 2019 Redistributable..."
    wget -q -O "$REDIST_DIR/VC_redist.x64.exe" \
        "https://aka.ms/vs/17/release/vc_redist.x64.exe" || true
    wget -q -O "$REDIST_DIR/VC_redist.x86.exe" \
        "https://aka.ms/vs/17/release/vc_redist.x86.exe" || true
    
    # .NET Framework 4.8
    echo "Downloading .NET Framework 4.8..."
    wget -q -O "$REDIST_DIR/ndp48-web.exe" \
        "https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP48-Web.exe" || true
    
    # Create a basic Proton prefix to populate caches
    echo "Initializing Proton cache prefix..."
    if [ -f "$PROTON_DIR/proton" ]; then
        # Initialize with a dummy app to populate caches
        echo "Warming up Proton caches..."
        timeout 60 "$PROTON_DIR/proton" waitforexitandrun echo "Proton cache initialized" || true
    fi
    
    # Pre-download common protontricks dependencies
    echo "Pre-downloading protontricks dependencies..."
    
    # Create protontricks cache directory
    mkdir -p ~/.cache/protontricks
    mkdir -p ~/.local/share/Steam/steamapps/compatdata
    
    # Download common Windows components used by protontricks
    PROTONTRICKS_CACHE="~/.cache/protontricks"
    
    # Pre-download winetricks cache for common verbs
    if command -v winetricks &> /dev/null; then
        echo "Pre-downloading winetricks cache..."
        
        # Download metadata
        winetricks --help > /dev/null 2>&1 || true
        
        # Common redistributables that games need
        for verb in vcrun2019 vcrun2015 vcrun2013 vcrun2012 vcrun2010 vcrun2008 vcrun2005 \
                   dotnet48 dotnet472 dotnet462 dotnet461 dotnet452 \
                   d3dcompiler_47 d3dx9 d3dx10 d3dx11_43 \
                   dxvk corefonts tahoma liberation msvcrt; do
            echo "Caching $verb..."
            timeout 30 winetricks --download-only "$verb" 2>/dev/null || true
        done
    fi
    
    # Pre-create Steam compatibility tool symlinks
    echo "Setting up Steam compatibility tools..."
    mkdir -p /opt/steam/compatibilitytools.d
    if [ ! -e "/opt/steam/compatibilitytools.d/GE-Proton10-3" ]; then
        ln -sf /opt/steam/compatibilitytools.d/GE-Proton10-3 /opt/steam/compatibilitytools.d/
    fi
    
    # Create default Steam config that recognizes Proton GE
    cat > /opt/steam/config/config.vdf << 'EOF'
"InstallConfigStore"
{
	"Software"
	{
		"Valve"
		{
			"Steam"
			{
				"CompatTools"
				{
					"GE-Proton10-3"
					{
						"tool" "GE-Proton10-3"
						"priority" "250"
					}
				}
			}
		}
	}
}
EOF
    
    # Set proper permissions
    chmod -R 755 /opt/steam/
    chmod -R 755 "$REDIST_DIR/" 2>/dev/null || true
    
    # Clean up temporary directories
    rm -rf /tmp/proton_cache /tmp/proton_wine_cache
    
    echo "Proton caches and dependencies pre-installed successfully"
}

# Execute installation
install_proton_cache