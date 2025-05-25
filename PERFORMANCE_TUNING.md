# Performance Tuning Guide

## GPU Acceleration

The system automatically detects and configures NVIDIA GPU acceleration. The following environment variables are set:

- `__GLX_VENDOR_LIBRARY_NAME=nvidia` - Forces OpenGL to use NVIDIA driver
- `__NV_PRIME_RENDER_OFFLOAD=1` - Enables PRIME render offload
- `__VK_LAYER_NV_optimus=NVIDIA_only` - Forces Vulkan to use NVIDIA GPU

## Video Streaming Optimization

### Selkies-gstreamer Configuration

By default, the system uses optimized x264 software encoding with these settings:

- Encoder: `x264enc tune=zerolatency speed-preset=ultrafast`
- Bitrate: 8000 kbps
- Hardware acceleration: Enabled when available

### Checking GPU Usage

```bash
# Check if GPU is being used for rendering
nvidia-smi

# Check OpenGL renderer
glxinfo | grep "OpenGL renderer"

# Monitor real-time GPU usage
watch -n 1 nvidia-smi
```

### Troubleshooting Low FPS

1. **Check encoder settings:**
   ```bash
   tail -n 100 /var/log/supervisor/selkies-gstreamer.log | grep encoder
   ```

2. **Verify GPU acceleration:**
   ```bash
   export __GLX_VENDOR_LIBRARY_NAME=nvidia
   glxinfo | grep "OpenGL renderer"
   ```

3. **Adjust video bitrate:**
   Edit `/opt/ai-dock/bin/supervisor-selkies-gstreamer.sh` and modify:
   ```bash
   export GST_VIDEO_BITRATE=12000  # Increase for better quality
   ```

### NVENC Support (Future)

Currently, NVENC hardware encoding requires additional setup. When available, you can enable it by:

```bash
export SELKIES_ENCODER=nvh264enc
```

## KDE Plasma Optimization

To reduce desktop effects for better streaming performance:

```bash
# Disable compositor
qdbus org.kde.KWin /Compositor suspend

# Re-enable compositor
qdbus org.kde.KWin /Compositor resume
```