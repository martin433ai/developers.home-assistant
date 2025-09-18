#!/usr/bin/env python3
"""
EAD Networks Configuration Server
A server application to manage Cloudflare settings, network routing, and HomeAssistant integration.
"""

from flask import Flask, jsonify, request, render_template_string
from flask_cors import CORS
import json
import os
import subprocess
import logging
from datetime import datetime
from typing import Dict, List, Optional
import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for HomeAssistant integration

# Configuration file paths
CONFIG_DIR = os.path.expanduser('~/.eadnets')
CONFIG_FILE = os.path.join(CONFIG_DIR, 'config.json')
NETWORK_CONFIG_FILE = os.path.join(CONFIG_DIR, 'network.json')
CLOUDFLARE_CONFIG_FILE = os.path.join(CONFIG_DIR, 'cloudflare.json')

# Ensure config directory exists
os.makedirs(CONFIG_DIR, exist_ok=True)

def load_config() -> Dict:
    """Load configuration from file or return defaults."""
    default_config = {
        "server": {
            "host": "0.0.0.0",
            "port": 8080,
            "debug": False
        },
        "cloudflare": {
            "tunnel_name": "ead-net-tunnel",
            "domain": "eadnets.com",
            "tunnel_id": None,
            "credentials_file": None
        },
        "network": {
            "interface": "utun5",
            "subnet": "192.168.100.0/24",
            "ip_address": "192.168.100.1"
        },
        "homeassistant": {
            "config_path": "/Users/martinpark/homeassistant_config",
            "port": 8123,
            "ssl": False
        },
        "esp_devices": []
    }
    
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r') as f:
                saved_config = json.load(f)
                # Merge with defaults
                for key in default_config:
                    if key in saved_config:
                        default_config[key].update(saved_config[key])
        except Exception as e:
            logger.error(f"Error loading config: {e}")
    
    return default_config

def save_config(config: Dict) -> bool:
    """Save configuration to file."""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        return True
    except Exception as e:
        logger.error(f"Error saving config: {e}")
        return False

def execute_command(command: List[str]) -> Dict:
    """Execute a system command and return result."""
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=30
        )
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Command timed out",
            "stdout": "",
            "stderr": "Timeout after 30 seconds"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "stdout": "",
            "stderr": str(e)
        }

# Web interface template
WEB_INTERFACE = """
<!DOCTYPE html>
<html>
<head>
    <title>EAD Networks Configuration Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .card { background: white; border-radius: 8px; padding: 20px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; }
        .status { padding: 10px; border-radius: 4px; margin: 10px 0; }
        .status.success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .status.error { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .status.warning { background-color: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
        .button { background-color: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
        .button:hover { background-color: #0056b3; }
        .button.danger { background-color: #dc3545; }
        .button.danger:hover { background-color: #c82333; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🌐 EAD Networks Configuration Server</h1>
        
        <div class="card">
            <h2>System Status</h2>
            <div id="system-status">Loading...</div>
            <button class="button" onclick="refreshStatus()">Refresh Status</button>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>Cloudflare Tunnel</h3>
                <div id="tunnel-status">Loading...</div>
                <button class="button" onclick="manageTunnel('start')">Start Tunnel</button>
                <button class="button" onclick="manageTunnel('stop')">Stop Tunnel</button>
                <button class="button" onclick="manageTunnel('status')">Check Status</button>
            </div>
            
            <div class="card">
                <h3>Network Configuration</h3>
                <div id="network-status">Loading...</div>
                <button class="button" onclick="configureNetwork()">Configure Network</button>
                <button class="button" onclick="checkNetwork()">Check Network</button>
            </div>
            
            <div class="card">
                <h3>HomeAssistant</h3>
                <div id="homeassistant-status">Loading...</div>
                <button class="button" onclick="checkHomeAssistant()">Check Status</button>
                <button class="button" onclick="restartHomeAssistant()">Restart</button>
            </div>
            
            <div class="card">
                <h3>ESP Devices</h3>
                <div id="esp-status">Loading...</div>
                <button class="button" onclick="scanDevices()">Scan Devices</button>
                <button class="button" onclick="configureDevices()">Configure</button>
            </div>
        </div>
        
        <div class="card">
            <h3>Configuration</h3>
            <pre id="current-config">Loading...</pre>
            <button class="button" onclick="editConfig()">Edit Configuration</button>
            <button class="button" onclick="saveConfig()">Save Configuration</button>
        </div>
        
        <div class="card">
            <h3>Logs</h3>
            <pre id="logs" style="height: 300px; overflow-y: auto;">Loading...</pre>
            <button class="button" onclick="refreshLogs()">Refresh Logs</button>
            <button class="button danger" onclick="clearLogs()">Clear Logs</button>
        </div>
    </div>

    <script>
        async function apiCall(endpoint, method = 'GET', data = null) {
            try {
                const options = { method, headers: { 'Content-Type': 'application/json' } };
                if (data) options.body = JSON.stringify(data);
                const response = await fetch(endpoint, options);
                return await response.json();
            } catch (error) {
                console.error('API call failed:', error);
                return { error: error.message };
            }
        }
        
        function formatStatus(data, containerId) {
            const container = document.getElementById(containerId);
            if (data.error) {
                container.innerHTML = `<div class="status error">Error: ${data.error}</div>`;
            } else if (data.success) {
                container.innerHTML = `<div class="status success">${data.message || 'Success'}</div>`;
            } else {
                container.innerHTML = `<div class="status warning">${data.message || 'Unknown status'}</div>`;
            }
        }
        
        async function refreshStatus() {
            const status = await apiCall('/api/status');
            formatStatus(status, 'system-status');
            
            // Update individual components
            const tunnel = await apiCall('/api/tunnel/status');
            formatStatus(tunnel, 'tunnel-status');
            
            const network = await apiCall('/api/network/status');
            formatStatus(network, 'network-status');
            
            const ha = await apiCall('/api/homeassistant/status');
            formatStatus(ha, 'homeassistant-status');
            
            const esp = await apiCall('/api/esp/status');
            formatStatus(esp, 'esp-status');
            
            // Update config
            const config = await apiCall('/api/config');
            document.getElementById('current-config').textContent = JSON.stringify(config, null, 2);
        }
        
        async function manageTunnel(action) {
            const result = await apiCall(`/api/tunnel/${action}`, 'POST');
            formatStatus(result, 'tunnel-status');
        }
        
        async function configureNetwork() {
            const result = await apiCall('/api/network/configure', 'POST');
            formatStatus(result, 'network-status');
        }
        
        async function checkNetwork() {
            const result = await apiCall('/api/network/status');
            formatStatus(result, 'network-status');
        }
        
        async function checkHomeAssistant() {
            const result = await apiCall('/api/homeassistant/status');
            formatStatus(result, 'homeassistant-status');
        }
        
        async function restartHomeAssistant() {
            const result = await apiCall('/api/homeassistant/restart', 'POST');
            formatStatus(result, 'homeassistant-status');
        }
        
        async function scanDevices() {
            const result = await apiCall('/api/esp/scan', 'POST');
            formatStatus(result, 'esp-status');
        }
        
        async function configureDevices() {
            const result = await apiCall('/api/esp/configure', 'POST');
            formatStatus(result, 'esp-status');
        }
        
        async function refreshLogs() {
            const logs = await apiCall('/api/logs');
            document.getElementById('logs').textContent = logs.logs || 'No logs available';
        }
        
        // Initialize page
        refreshStatus();
        refreshLogs();
        
        // Auto-refresh every 30 seconds
        setInterval(refreshStatus, 30000);
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    """Serve the main web interface."""
    return render_template_string(WEB_INTERFACE)

@app.route('/api/status')
def api_status():
    """Get overall system status."""
    try:
        config = load_config()
        return jsonify({
            "success": True,
            "message": "EAD Networks server running",
            "timestamp": datetime.now().isoformat(),
            "version": "1.0.0"
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/config', methods=['GET'])
def api_get_config():
    """Get current configuration."""
    try:
        config = load_config()
        return jsonify(config)
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/config', methods=['POST'])
def api_save_config():
    """Save configuration."""
    try:
        new_config = request.json
        success = save_config(new_config)
        if success:
            return jsonify({"success": True, "message": "Configuration saved"})
        else:
            return jsonify({"success": False, "error": "Failed to save configuration"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/tunnel/status')
def api_tunnel_status():
    """Check Cloudflare tunnel status."""
    try:
        result = execute_command(['cloudflared', 'tunnel', 'list'])
        if result['success']:
            return jsonify({
                "success": True,
                "message": "Tunnel list retrieved",
                "output": result['stdout']
            })
        else:
            return jsonify({
                "success": False,
                "error": result['stderr'],
                "message": "Failed to get tunnel status"
            })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/tunnel/<action>', methods=['POST'])
def api_tunnel_action(action):
    """Perform tunnel actions: start, stop, create."""
    try:
        config = load_config()
        tunnel_name = config['cloudflare']['tunnel_name']
        
        if action == 'start':
            result = execute_command(['cloudflared', 'tunnel', 'run', tunnel_name])
        elif action == 'stop':
            result = execute_command(['pkill', '-f', 'cloudflared'])
        elif action == 'create':
            result = execute_command(['cloudflared', 'tunnel', 'create', tunnel_name])
        elif action == 'status':
            result = execute_command(['cloudflared', 'tunnel', 'list'])
        else:
            return jsonify({"success": False, "error": "Invalid action"})
        
        return jsonify({
            "success": result['success'],
            "message": f"Tunnel {action} executed",
            "output": result['stdout'],
            "error": result['stderr'] if not result['success'] else None
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/network/status')
def api_network_status():
    """Check network configuration status."""
    try:
        config = load_config()
        interface = config['network']['interface']
        
        result = execute_command(['ifconfig', interface])
        if result['success']:
            return jsonify({
                "success": True,
                "message": f"Network interface {interface} status",
                "output": result['stdout']
            })
        else:
            return jsonify({
                "success": False,
                "error": f"Interface {interface} not found or error",
                "output": result['stderr']
            })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/network/configure', methods=['POST'])
def api_network_configure():
    """Configure network interface and routing."""
    try:
        config = load_config()
        interface = config['network']['interface']
        ip_address = config['network']['ip_address']
        subnet = config['network']['subnet']
        
        # This is a placeholder - actual network configuration would require sudo
        return jsonify({
            "success": True,
            "message": f"Network configuration for {interface} would be applied",
            "note": "Actual configuration requires administrator privileges"
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/homeassistant/status')
def api_homeassistant_status():
    """Check HomeAssistant status."""
    try:
        result = execute_command(['ps', 'aux'])
        if 'homeassistant' in result['stdout'] or 'hass' in result['stdout']:
            return jsonify({
                "success": True,
                "message": "HomeAssistant is running"
            })
        else:
            return jsonify({
                "success": False,
                "message": "HomeAssistant not running"
            })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/esp/status')
def api_esp_status():
    """Check ESP device status."""
    try:
        config = load_config()
        devices = config.get('esp_devices', [])
        return jsonify({
            "success": True,
            "message": f"Found {len(devices)} ESP devices",
            "devices": devices
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/logs')
def api_logs():
    """Get system logs."""
    try:
        # This is a simple implementation - in production, you'd want proper log management
        log_file = os.path.join(CONFIG_DIR, 'server.log')
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                logs = f.read()
        else:
            logs = "No logs available"
        
        return jsonify({
            "success": True,
            "logs": logs
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

if __name__ == '__main__':
    config = load_config()
    
    # Set up logging to file
    log_file = os.path.join(CONFIG_DIR, 'server.log')
    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    ))
    logger.addHandler(file_handler)
    
    logger.info("Starting EAD Networks Configuration Server")
    logger.info(f"Config directory: {CONFIG_DIR}")
    logger.info(f"Configuration loaded: {json.dumps(config, indent=2)}")
    
    app.run(
        host=config['server']['host'],
        port=config['server']['port'],
        debug=config['server']['debug']
    )