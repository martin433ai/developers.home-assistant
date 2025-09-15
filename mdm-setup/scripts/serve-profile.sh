#!/bin/bash

# Simple HTTP server to serve enrollment profile to iPhone
# The iPhone can access this via Tailscale network

TAILSCALE_IP=$(tailscale ip -4)
PORT=8000
PROFILE_PATH="/Users/martinpark/mdm-setup/profiles"

echo "🌐 Starting HTTP server for enrollment profile..."
echo "📱 iPhone can access the profile at:"
echo "   http://${TAILSCALE_IP}:${PORT}/enrollment.mobileconfig"
echo ""
echo "📋 Instructions for iPhone:"
echo "1. On iPhone, open Safari"
echo "2. Go to: http://${TAILSCALE_IP}:${PORT}/enrollment.mobileconfig"
echo "3. Tap 'Allow' to download the profile"
echo "4. Go to Settings > General > VPN & Device Management"
echo "5. Tap the profile and install it"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

cd "$PROFILE_PATH"
python3 -m http.server $PORT --bind $TAILSCALE_IP