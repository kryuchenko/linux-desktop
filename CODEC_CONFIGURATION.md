# Codec Configuration Guide

## Supported Codecs for Selkies-gstreamer

### 1. NVIDIA Hardware Codecs (Best Performance)

**H.264 (Recommended):**
```bash
# Low latency streaming
export SELKIES_ENCODER="nvh264enc bitrate=8000 preset=low-latency-hq rc-mode=cbr-hq gop-size=60"

# Quality mode
export SELKIES_ENCODER="nvh264enc bitrate=12000 preset=slow rc-mode=vbr-hq"

# Ultra low latency
export SELKIES_ENCODER="nvh264enc bitrate=6000 preset=low-latency-hp rc-mode=cbr zerolatency=true"
```

**H.265/HEVC (Better compression):**
```bash
# For lower bandwidth
export SELKIES_ENCODER="nvh265enc bitrate=4000 preset=low-latency-hq rc-mode=cbr-hq"
```

**AV1 (RTX 40/50 series only):**
```bash
# Future support
export SELKIES_ENCODER="nvav1enc bitrate=3000 preset=p4"
```

### 2. Software Codecs (Fallback)

**x264 (Current default):**
```bash
# Optimized for low latency
export SELKIES_ENCODER="x264enc tune=zerolatency speed-preset=ultrafast bitrate=8000"

# Better quality
export SELKIES_ENCODER="x264enc tune=zerolatency speed-preset=medium bitrate=10000"
```

**VP8/VP9 (WebRTC native):**
```bash
# VP8 - faster
export SELKIES_ENCODER="vp8enc deadline=1 cpu-used=8 target-bitrate=8000000"

# VP9 - better quality
export SELKIES_ENCODER="vp9enc deadline=1 cpu-used=8 target-bitrate=6000000"
```

### 3. Codec Selection Priority

The system automatically selects codecs in this order:
1. `nvh264enc` - NVIDIA hardware H.264 (if available)
2. `x264enc` - Software H.264 (always available)
3. `vp8enc` - VP8 software encoder

### 4. Bandwidth Recommendations

| Resolution | NVENC H.264 | x264 | NVENC H.265 | VP9 |
|------------|-------------|------|--------------|-----|
| 1920x1080  | 8 Mbps     | 8-10 Mbps | 4-6 Mbps | 6 Mbps |
| 2560x1440  | 12 Mbps    | 15 Mbps   | 8 Mbps   | 10 Mbps |
| 3840x2160  | 20 Mbps    | 25 Mbps   | 15 Mbps  | 18 Mbps |

### 5. Testing Codecs

```bash
# Check available codecs
/opt/ai-dock/bin/check-nvenc.sh

# Test specific encoder
gst-launch-1.0 videotestsrc num-buffers=300 ! \
    video/x-raw,width=1920,height=1080,framerate=60/1 ! \
    nvh264enc bitrate=8000 ! \
    h264parse ! mp4mux ! filesink location=test.mp4

# Monitor encoding performance
nvidia-smi dmon -s pucvmet
```

### 6. Environment Variables

```bash
# Set in supervisor config or environment
SELKIES_ENCODER=nvh264enc
SELKIES_VIDEO_CODEC=H264
GST_VIDEO_BITRATE=8000
SELKIES_FRAMERATE=60
SELKIES_VIDEO_RESIZE_MODE=2  # 0=none, 1=scale, 2=crop

# For debugging
GST_DEBUG=*:3,nvenc:5
```

### 7. Troubleshooting

**NVENC not available:**
- Check driver version: `nvidia-smi` (need 470+)
- Verify NVENC support: `nvidia-smi -q | grep -i encoder`
- Check gstreamer plugin: `gst-inspect-1.0 nvcodec`

**High latency:**
- Use `zerolatency=true` parameter
- Reduce GOP size: `gop-size=30`
- Enable CBR mode: `rc-mode=cbr`

**Poor quality:**
- Increase bitrate
- Change preset to `medium` or `slow`
- Use VBR mode: `rc-mode=vbr-hq`