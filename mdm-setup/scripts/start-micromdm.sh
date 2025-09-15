#!/bin/bash

# MicroMDM Server Startup Script
# Configured for Tailscale network management

TAILSCALE_IP=$(tailscale ip -4)
MDM_DIR="/Users/martinpark/mdm-setup"
API_KEY=$(cat "${MDM_DIR}/api-key.txt")
TLS_CERT="${MDM_DIR}/certs/server.crt"
TLS_KEY="${MDM_DIR}/certs/server.key"
CONFIG_PATH="${MDM_DIR}/config"
SERVER_URL="https://${TAILSCALE_IP}:8443"

echo "Starting MicroMDM server..."
echo "Tailscale IP: ${TAILSCALE_IP}"
echo "Server URL: ${SERVER_URL}"
echo "Config Path: ${CONFIG_PATH}"

# Create config directory if it doesn't exist
mkdir -p "${CONFIG_PATH}"

# Start MicroMDM server
exec micromdm serve \
    -server-url="${SERVER_URL}" \
    -api-key="${API_KEY}" \
    -tls-cert="${TLS_CERT}" \
    -tls-key="${TLS_KEY}" \
    -config-path="${CONFIG_PATH}" \
    -http-addr=":8443" \
    -homepage=true \
    -log-time=true