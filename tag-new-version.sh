#!/bin/bash
# Tag new version after websockets fix

# Version with websockets fix
NEW_VERSION="v1.6.3"

# Get current commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)

# Create annotated tag
git tag -a "${NEW_VERSION}" -m "Fix selkies-gstreamer websockets compatibility

- Upgrade websockets to >=11 for Python 3.10+ compatibility
- Install libwebrtc-audio-processing1 library
- Fix Vast.ai 'Internal error' issue
- Fix WebRTC connection issues

Commit: ${COMMIT_HASH}"

echo "Created tag: ${NEW_VERSION}"
echo "To push: git push origin ${NEW_VERSION}"