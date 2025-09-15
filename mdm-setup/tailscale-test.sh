#!/bin/bash

# Tailscale Exit Node Testing Script
echo "=== Tailscale Exit Node Configuration Test ==="
echo

# Get current configuration
echo "1. Current Tailscale Status:"
tailscale status
echo

echo "2. Current IP Configuration:"
echo "Mac IP: $(ifconfig | grep -E "192\.168\.|10\.|172\." | grep inet | head -1 | awk '{print $2}')"
echo "Gateway: $(route get default | grep gateway | awk '{print $2}')"
echo "Tailscale IP: $(tailscale ip)"
echo

echo "3. Testing connectivity:"
echo "Pinging Google DNS:"
ping -c 3 8.8.8.8
echo

echo "4. Checking public IP (should show Tailscale exit node IP when active):"
curl -s https://ipinfo.io/ip
echo
echo

echo "5. DNS Resolution Test:"
nslookup google.com
echo

echo "6. Testing Tailscale DNS:"
nslookup google.com $(tailscale ip)
echo

echo "=== Test Complete ==="
echo "If you're using this Mac as exit node from another device:"
echo "- The public IP should match your home ISP"
echo "- DNS should resolve properly"
echo "- Local network devices should still be accessible"