# Apple Configurator iPhone Supervision Checklist

## ✅ COMPLETED PREPARATIONS
- [x] iTunes/Finder encrypted backup is running
- [x] MicroMDM server running on Tailscale: https://***:8443
- [x] MDM certificate ready: ~/mdm-setup/certs/mdm-certificate.pem
- [x] iPhone connected via Thunderbolt 3 dock
- [x] iPhone device info backed up

## 📋 APPLE CONFIGURATOR SETUP STEPS

### Certificate Information:
- **File**: `/Users/martinpark/mdm-setup/certs/mdm-certificate.pem`
- **Type**: Apple Push Notification Service (MDM)
- **Valid**: May 7, 2025 - May 7, 2026
- **Subject**: APSP:aa1c6e81-93ae-4e7d-b2c2-3ca51016fe26

### Apple Configurator Steps:
1. **Open Apple Configurator** (already running)
2. **Select your iPhone** in device list
3. **Click "Prepare"** → **"Manual Configuration"**
4. **Enable "Supervise devices"** ✅ CRITICAL
5. **Enable "Allow devices to pair with other computers"**
6. **Organization Setup:**
   - Organization Name: "Personal MDM" (or your preference)
   - Use certificate: `mdm-certificate.pem`
7. **Start preparation** (this will WIPE the device)

### After Supervision:
1. Device will reboot and show Apple logo
2. iOS will be reinstalled fresh
3. Device will show "This iPhone is supervised and managed"
4. Connect to Wi-Fi and complete basic setup
5. Install MDM enrollment profile

## 🔧 MDM ENROLLMENT PROFILE
Ready at: `~/mdm-setup/profiles/enrollment.mobileconfig`
Server URL: `https://***:8443/mdm/apple/mdm`

## ⚠️ CRITICAL WARNINGS
- This process will COMPLETELY WIPE your iPhone
- Ensure iTunes backup is COMPLETE before proceeding
- Have your Apple ID credentials ready for re-setup
- Process takes 15-30 minutes total

## 📱 DEVICE INFO
- UDID: 00008030-000338A602BA802E
- Model: iPhone 11 Pro (iPhone12,3)
- Current iOS: 18.5
- Connection: USB via Thunderbolt 3 dock ✅ Working
