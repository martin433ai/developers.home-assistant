# EAD Networks Configuration Server

A comprehensive configuration server for managing the homeassistant-eadnets.com project, including Cloudflare tunnel management, network routing, and ESP-IDF device integration.

## Features

- 🌐 **Web Interface**: User-friendly web dashboard for managing all components
- 🔗 **Cloudflare Tunnel Management**: Create, start, stop, and monitor Cloudflare tunnels
- 📡 **Network Configuration**: Manage utun interfaces and routing for /24 subnets
- 🏠 **HomeAssistant Integration**: Monitor and control HomeAssistant instance
- 📟 **ESP Device Management**: Discover and configure ESP-IDF devices
- 📊 **Real-time Status**: Live monitoring of all system components
- 🔧 **Configuration API**: RESTful API for programmatic access

## Quick Start

1. **Start the server**:
   ```bash
   cd /Users/martinpark/eadnets-server
   ./start-server.sh
   ```

2. **Access the web interface**:
   Open http://localhost:8080 in your browser

3. **Configure your settings**:
   - Use the web interface to configure Cloudflare settings
   - Set up network parameters
   - Configure ESP device connections

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web Browser   │    │  EAD Networks    │    │   Cloudflare    │
│                 │◄──►│  Config Server   │◄──►│     Tunnel      │
│  localhost:8080 │    │   (Port 8080)    │    │  eadnets.com    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ HomeAssistant │  │   Network    │  │ ESP Devices  │
    │ (Port 8123)   │  │  Interface   │  │  (ESP-IDF)   │
    └──────────────┘  │  (utun5)     │  └──────────────┘
                      └──────────────┘
```

## API Endpoints

### System Status
- `GET /api/status` - Get overall system status
- `GET /api/config` - Get current configuration
- `POST /api/config` - Update configuration

### Cloudflare Tunnel
- `GET /api/tunnel/status` - Check tunnel status
- `POST /api/tunnel/start` - Start tunnel
- `POST /api/tunnel/stop` - Stop tunnel
- `POST /api/tunnel/create` - Create new tunnel

### Network Management
- `GET /api/network/status` - Check network interface status
- `POST /api/network/configure` - Configure network routing

### HomeAssistant
- `GET /api/homeassistant/status` - Check HomeAssistant status
- `POST /api/homeassistant/restart` - Restart HomeAssistant

### ESP Devices
- `GET /api/esp/status` - Get ESP device status
- `POST /api/esp/scan` - Scan for ESP devices
- `POST /api/esp/configure` - Configure ESP devices

### Logs
- `GET /api/logs` - Get system logs

## Configuration

Configuration files are stored in `~/.eadnets/`:

- `config.json` - Main configuration file
- `server.log` - Server log file

### Default Configuration

```json
{
  "server": {
    "host": "0.0.0.0",
    "port": 8080,
    "debug": false
  },
  "cloudflare": {
    "tunnel_name": "ead-net-tunnel",
    "domain": "eadnets.com",
    "tunnel_id": null,
    "credentials_file": null
  },
  "network": {
    "interface": "utun5",
    "subnet": "192.168.100.0/24",
    "ip_address": "192.168.100.1"
  },
  "homeassistant": {
    "config_path": "/Users/martinpark/homeassistant_config",
    "port": 8123,
    "ssl": false
  },
  "esp_devices": []
}
```

## Requirements

- Python 3.8+
- Flask 2.3.3
- Flask-CORS 4.0.0
- PyYAML 6.0.1
- Cloudflared CLI tool
- HomeAssistant (running)

## Installation

The server will automatically install dependencies when you run `./start-server.sh`.

Manual installation:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Development

To run in development mode:
```bash
export FLASK_ENV=development
python3 app.py
```

## Security Notes

- The server runs on all interfaces (0.0.0.0) by default
- For production use, consider:
  - Adding authentication
  - Using HTTPS
  - Restricting access by IP
  - Implementing rate limiting

## Troubleshooting

1. **Port 8080 already in use**:
   - Change the port in the configuration file
   - Or stop the conflicting service

2. **Cloudflare authentication issues**:
   - Run `cloudflared tunnel login` to re-authenticate
   - Check that your Cloudflare account has tunnel permissions

3. **Permission denied for network configuration**:
   - Network configuration requires administrator privileges
   - Run with `sudo` for network changes

4. **HomeAssistant not detected**:
   - Ensure HomeAssistant is running
   - Check the config_path in the configuration

## Next Steps

1. Configure Cloudflare tunnel authentication
2. Set up network routing for utun interface
3. Connect ESP-IDF devices
4. Configure HomeAssistant integration
5. Set up automatic service startup

## License

MIT License - Part of the homeassistant-eadnets.com project