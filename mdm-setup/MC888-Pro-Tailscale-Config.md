# MC888 Pro Router Configuration for Tailscale Exit Node

## Overview
This guide configures your Huawei MC888 Pro router to route all network traffic through your Mac as a Tailscale exit node, allowing all devices (ethernet, WiFi, IoT) to access your Tailscale network.

## Prerequisites
✅ Mac configured as Tailscale exit node (completed)
✅ Exit node and subnet routes approved in Tailscale admin console (required)

## Your Network Information
- **Mac IP Address**: [Check with command: `ifconfig | grep inet | grep -E "192\.168\.|10\.|172\." | head -1 | awk '{print $2}'`]
- **Mac MAC Address**: [Check with command: `ifconfig | grep ether | head -1 | awk '{print $2}'`]
- **Router Gateway IP**: [Check with command: `route get default | grep gateway | awk '{print $2}'`]
- **Network Subnet**: Likely 192.168.1.0/24

## Step-by-Step Configuration

### 1. Access Router Admin Interface
1. Open web browser
2. Go to: `http://[your_gateway_ip]` (typically 192.168.1.1)
3. Login with admin credentials

### 2. Reserve Static IP for Mac
**Path: Advanced Settings → DHCP → Static IP Assignment**
- MAC Address: [Your Mac's MAC]
- IP Address: [Your Mac's current IP]
- Click "Add" and "Apply"

### 3. Configure Static Routes (Primary Method)
**Path: Advanced Settings → Network → Routing → Static Routes**

Add new route:
- **Destination Network**: 0.0.0.0
- **Subnet Mask**: 0.0.0.0
- **Gateway**: [Your Mac's IP]
- **Interface**: LAN
- **Metric**: 1

Click "Add" and "Apply"

### 4. Alternative: DMZ Configuration (If static routes unavailable)
**Path: Advanced Settings → Security → DMZ**
- Enable DMZ
- DMZ Host IP: [Your Mac's IP]
- Click "Apply"

### 5. Configure DNS Settings
**Path: Advanced Settings → Network → DHCP**
- **Primary DNS**: [Your Mac's IP]
- **Secondary DNS**: 8.8.8.8
- Click "Apply"

### 6. WiFi Network Configuration
For both M#M1Smartbix and M#M5GKasserolle:
**Path: WiFi Settings → [Network Name] → Advanced**
- Ensure same subnet as main network
- Verify DHCP settings match main network

### 7. Additional IoT Device Considerations

**For Philips Hue Bridge:**
- Should automatically use new routing
- Verify in Hue app that bridge is still accessible

**For HomeAssistant Green:**
- May need to configure static route in HA if it has its own routing table
- Check HA network settings if connectivity issues occur

**For HomePod Mini & Google Nest Mini:**
- These should automatically use new routing
- Test voice commands that require internet

**For Apple TV 3rd Generation:**
- Will now have Tailscale connectivity through router
- Test streaming services and AirPlay functionality

## Testing Configuration

Run the test script: `./tailscale-test.sh`

### Manual Testing Steps:
1. **From any device on your network:**
   ```bash
   # Check what your public IP is now
   curl https://ipinfo.io/ip
   ```

2. **From another Tailscale device (phone, etc.):**
   - Connect to your Mac as exit node in Tailscale app
   - Check public IP - should match your home ISP
   - Try accessing local devices (192.168.1.x addresses)

3. **Test each device type:**
   - Ethernet devices: Check internet connectivity
   - WiFi devices: Test both networks
   - IoT devices: Verify functionality
   - Smart home devices: Test app connectivity

## Troubleshooting

### If devices can't access internet:
1. Check static routes are applied
2. Verify Mac's IP hasn't changed
3. Ensure Tailscale is running on Mac
4. Check firewall settings on Mac

### If local devices unreachable:
1. Verify subnet routes are approved in Tailscale
2. Check Mac can ping local devices
3. Ensure --accept-routes is enabled

### If DNS not working:
1. Verify DNS settings in router
2. Test: `nslookup google.com [mac-ip]`
3. Check Tailscale MagicDNS is enabled

## Monitoring and Maintenance

### Regular Checks:
- Monitor Tailscale status: `tailscale status`
- Check Mac uptime and connectivity
- Verify router hasn't reset static routes
- Test connectivity from various devices

### Backup Configuration:
- Export router settings periodically
- Document any custom configurations
- Keep record of all IP addresses and settings

## Rollback Plan
If issues occur:
1. Remove static routes from router
2. Reset DNS to automatic/ISP provided
3. Disable DMZ if configured
4. Router will revert to direct internet access

## Contact Information
- Tailscale Admin Console: https://login.tailscale.com/admin/machines
- Router manual: Check Huawei support for MC888 Pro