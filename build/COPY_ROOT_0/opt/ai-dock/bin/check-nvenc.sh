#!/bin/bash

echo "=== NVENC Hardware Encoder Check ==="
echo

# Check NVIDIA driver
echo "1. NVIDIA Driver:"
nvidia-smi --query-gpu=driver_version --format=csv,noheader || echo "NVIDIA driver not found"
echo

# Check NVENC support
echo "2. NVENC Support in GPU:"
nvidia-smi -q | grep -i "encoder" | head -10 || echo "Could not query encoder support"
echo

# Check libnvidia-encode
echo "3. NVENC Library:"
ldconfig -p | grep nvidia-encode || echo "libnvidia-encode.so not found in ldconfig"
ls -la /usr/lib/x86_64-linux-gnu/libnvidia-encode.so* 2>/dev/null || echo "libnvidia-encode.so not found"
echo

# Check GStreamer plugin
echo "4. GStreamer NVENC Plugin:"
if command -v gst-inspect-1.0 &>/dev/null; then
    gst-inspect-1.0 nvh264enc &>/dev/null && echo "✓ nvh264enc is available" || echo "✗ nvh264enc NOT available"
    gst-inspect-1.0 nvcodec 2>/dev/null | grep -E "nvh264enc|nvh265enc" || true
else
    echo "gst-inspect-1.0 not found"
fi
echo

# Test NVENC encoding
echo "5. Test NVENC Encoding:"
if command -v gst-launch-1.0 &>/dev/null && gst-inspect-1.0 nvh264enc &>/dev/null; then
    echo "Testing NVENC encoding..."
    timeout 5 gst-launch-1.0 videotestsrc num-buffers=100 ! \
        'video/x-raw,width=1920,height=1080,framerate=30/1' ! \
        nvh264enc preset=low-latency-hq ! \
        h264parse ! mp4mux ! filesink location=/tmp/nvenc-test.mp4 &>/dev/null
    
    if [ -f /tmp/nvenc-test.mp4 ]; then
        echo "✓ NVENC test successful"
        ls -lh /tmp/nvenc-test.mp4
        rm -f /tmp/nvenc-test.mp4
    else
        echo "✗ NVENC test failed"
    fi
else
    echo "Cannot test NVENC - gst-launch-1.0 or nvh264enc not available"
fi
echo

echo "=== Summary ==="
if gst-inspect-1.0 nvh264enc &>/dev/null 2>&1; then
    echo "✓ NVENC is available and ready to use"
else
    echo "✗ NVENC is NOT available. Using software encoding (x264enc)"
fi