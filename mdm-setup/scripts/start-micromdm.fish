#!/usr/bin/env fish

# MicroMDM Server Startup Script
# Configured for Tailscale network management

set TAILSCALE_IP (tailscale ip -4)
set MDM_DIR "/Users/martinpark/mdm-setup"
set API_KEY (cat "$MDM_DIR/api-key.txt")
set TLS_CERT "$MDM_DIR/certs/server.crt"
set TLS_KEY "$MDM_DIR/certs/server.key"
set CONFIG_PATH "$MDM_DIR/config"
set SERVER_URL "https://$TAILSCALE_IP:8443"

echo "Starting MicroMDM server..."
echo "Tailscale IP: $TAILSCALE_IP"
echo "Server URL: $SERVER_URL"
echo "Config Path: $CONFIG_PATH"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_PATH"

# Start MicroMDM server
exec micromdm serve \
    -server-url="$SERVER_URL" \
    -api-key="$API_KEY" \
    -tls-cert="$TLS_CERT" \
    -tls-key="$TLS_KEY" \
    -config-path="$CONFIG_PATH" \
    -http-addr=":8443" \
    -homepage=true \
    -log-time=true