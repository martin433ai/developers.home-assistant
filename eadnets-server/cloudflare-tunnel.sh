#!/bin/bash

# Cloudflare Tunnel Management Script for EAD Networks
set -e

TUNNEL_NAME="ead-net-tunnel"
CONFIG_FILE="$HOME/.cloudflared/config.yml"
CREDENTIALS_DIR="$HOME/.cloudflared"
LOG_FILE="$HOME/.cloudflared/tunnel.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_dependencies() {
    echo_info "Checking dependencies..."
    
    if ! command -v cloudflared &> /dev/null; then
        echo_error "cloudflared is not installed"
        echo_info "Install with: brew install cloudflare/cloudflare/cloudflared"
        exit 1
    fi
    
    if [ ! -f "$CREDENTIALS_DIR/cert.pem" ]; then
        echo_error "Cloudflare certificate not found"
        echo_info "Run: cloudflared tunnel login"
        exit 1
    fi
    
    echo_success "Dependencies OK"
}

validate_config() {
    echo_info "Validating tunnel configuration..."
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo_error "Tunnel configuration not found at $CONFIG_FILE"
        exit 1
    fi
    
    # Test configuration syntax
    if cloudflared tunnel ingress validate; then
        echo_success "Configuration is valid"
    else
        echo_error "Configuration validation failed"
        exit 1
    fi
}

get_tunnel_info() {
    echo_info "Getting tunnel information..."
    
    # Try to get tunnel info (may fail due to API permissions)
    if cloudflared tunnel list 2>/dev/null | grep -q "$TUNNEL_NAME"; then
        TUNNEL_ID=$(cloudflared tunnel list 2>/dev/null | grep "$TUNNEL_NAME" | awk '{print $1}')
        echo_success "Found tunnel: $TUNNEL_NAME (ID: $TUNNEL_ID)"
        return 0
    else
        echo_warning "Could not retrieve tunnel list (may be due to API permissions)"
        echo_info "This is OK - we can still run the tunnel if it exists"
        return 1
    fi
}

create_tunnel() {
    echo_info "Attempting to create tunnel: $TUNNEL_NAME"
    
    if cloudflared tunnel create "$TUNNEL_NAME"; then
        echo_success "Tunnel created successfully"
        get_tunnel_info
    else
        echo_warning "Failed to create tunnel (may already exist or lack permissions)"
        echo_info "Continuing with existing configuration..."
    fi
}

setup_dns() {
    echo_info "Setting up DNS routes..."
    
    local domains=("eadnets.com" "homeassistant.eadnets.com" "api.eadnets.com")
    
    for domain in "${domains[@]}"; do
        echo_info "Setting up DNS for $domain..."
        if cloudflared tunnel route dns "$TUNNEL_NAME" "$domain" 2>/dev/null; then
            echo_success "DNS route created for $domain"
        else
            echo_warning "Could not create DNS route for $domain (may lack permissions)"
            echo_info "You may need to manually add CNAME record: $domain -> $TUNNEL_NAME.cfargotunnel.com"
        fi
    done
}

start_tunnel() {
    echo_info "Starting Cloudflare tunnel..."
    
    # Check if tunnel is already running
    if pgrep -f "cloudflared.*tunnel.*run" > /dev/null; then
        echo_warning "Tunnel appears to be already running"
        echo_info "Use 'stop' command first if you want to restart"
        return 1
    fi
    
    # Start tunnel in background
    nohup cloudflared tunnel run "$TUNNEL_NAME" > "$LOG_FILE" 2>&1 &
    TUNNEL_PID=$!
    
    sleep 3
    
    if kill -0 "$TUNNEL_PID" 2>/dev/null; then
        echo_success "Tunnel started successfully (PID: $TUNNEL_PID)"
        echo_info "Log file: $LOG_FILE"
        echo_info "Tunnel should be accessible at:"
        echo "  • https://eadnets.com (Configuration Server)"
        echo "  • https://homeassistant.eadnets.com (HomeAssistant)"
        echo "  • https://api.eadnets.com (API)"
    else
        echo_error "Failed to start tunnel"
        if [ -f "$LOG_FILE" ]; then
            echo_info "Check logs: tail -f $LOG_FILE"
        fi
        return 1
    fi
}

stop_tunnel() {
    echo_info "Stopping Cloudflare tunnel..."
    
    if pgrep -f "cloudflared.*tunnel.*run" > /dev/null; then
        pkill -f "cloudflared.*tunnel.*run"
        echo_success "Tunnel stopped"
    else
        echo_warning "No tunnel process found"
    fi
}

show_status() {
    echo_info "Cloudflare Tunnel Status"
    echo "========================"
    
    # Check if tunnel process is running
    if pgrep -f "cloudflared.*tunnel.*run" > /dev/null; then
        TUNNEL_PID=$(pgrep -f "cloudflared.*tunnel.*run")
        echo_success "Tunnel is running (PID: $TUNNEL_PID)"
    else
        echo_warning "Tunnel is not running"
    fi
    
    # Check configuration
    if [ -f "$CONFIG_FILE" ]; then
        echo_info "Configuration: $CONFIG_FILE"
    else
        echo_error "Configuration file not found"
    fi
    
    # Show log file status
    if [ -f "$LOG_FILE" ]; then
        echo_info "Log file: $LOG_FILE ($(wc -l < "$LOG_FILE") lines)"
        echo_info "Recent log entries:"
        tail -5 "$LOG_FILE" | sed 's/^/  /'
    else
        echo_warning "No log file found"
    fi
}

show_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo_info "Showing tunnel logs (last 50 lines):"
        echo "======================================"
        tail -50 "$LOG_FILE"
        echo "======================================"
        echo_info "To follow logs in real-time: tail -f $LOG_FILE"
    else
        echo_warning "No log file found at $LOG_FILE"
    fi
}

test_tunnel() {
    echo_info "Testing tunnel connectivity..."
    
    local domains=("eadnets.com" "homeassistant.eadnets.com" "api.eadnets.com")
    
    for domain in "${domains[@]}"; do
        echo_info "Testing $domain..."
        if curl -s -o /dev/null -w "%{http_code}" "https://$domain" | grep -q "200\|301\|302"; then
            echo_success "$domain is accessible"
        else
            echo_warning "$domain is not accessible (may take a few minutes to propagate)"
        fi
    done
}

case "$1" in
    setup)
        echo_info "Setting up Cloudflare tunnel..."
        check_dependencies
        create_tunnel
        setup_dns
        echo_success "Setup complete! Use 'start' to run the tunnel."
        ;;
    start)
        check_dependencies
        validate_config
        start_tunnel
        ;;
    stop)
        stop_tunnel
        ;;
    restart)
        stop_tunnel
        sleep 2
        start_tunnel
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    test)
        test_tunnel
        ;;
    validate)
        check_dependencies
        validate_config
        echo_success "Configuration is valid"
        ;;
    *)
        echo "Cloudflare Tunnel Management for EAD Networks"
        echo "Usage: $0 {setup|start|stop|restart|status|logs|test|validate}"
        echo ""
        echo "Commands:"
        echo "  setup    - Create tunnel and configure DNS"
        echo "  start    - Start the tunnel"
        echo "  stop     - Stop the tunnel"
        echo "  restart  - Restart the tunnel"
        echo "  status   - Show tunnel status"
        echo "  logs     - Show tunnel logs"
        echo "  test     - Test tunnel connectivity"
        echo "  validate - Validate configuration"
        echo ""
        echo "Configuration: $CONFIG_FILE"
        echo "Logs: $LOG_FILE"
        exit 1
        ;;
esac