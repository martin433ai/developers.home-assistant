#!/bin/bash

# iPhone Backup Script
# Creates comprehensive backup before MDM supervision

BACKUP_DIR="$HOME/mdm-setup/backups/$(date +%Y%m%d_%H%M%S)"
UDID="00008030-000338A602BA802E"

echo "🔄 Creating iPhone backup in: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"/{device_info,apps,photos,documents,system}

# 1. Device Information
echo "📱 Backing up device information..."
ideviceinfo -s > "$BACKUP_DIR/device_info/device_info.txt"
ideviceinfo -s -k InstalledApplications > "$BACKUP_DIR/device_info/installed_apps.txt" 2>/dev/null || echo "Apps list unavailable"

# 2. Try to backup photos using libimobiledevice
echo "📸 Attempting to backup photos..."
if command -v ifuse >/dev/null 2>&1; then
    echo "Using ifuse method..."
    mkdir -p "/tmp/iphone_mount"
    ifuse "/tmp/iphone_mount" --documents
    if [ $? -eq 0 ]; then
        cp -r "/tmp/iphone_mount/DCIM" "$BACKUP_DIR/photos/" 2>/dev/null || echo "DCIM not accessible"
        umount "/tmp/iphone_mount"
        rmdir "/tmp/iphone_mount"
    fi
else
    echo "⚠️  ifuse not available. Photos backup limited."
    echo "Recommendation: Use iTunes/Finder backup or iCloud Photos sync"
fi

# 3. App data (limited due to iOS sandboxing)
echo "📱 Getting app information..."
ideviceinstaller -l > "$BACKUP_DIR/apps/app_list.txt" 2>/dev/null || echo "App list unavailable"

# 4. System logs and crash reports
echo "📋 Backing up system information..."
idevicesyslog --quiet > "$BACKUP_DIR/system/syslog_sample.txt" &
SYSLOG_PID=$!
sleep 5
kill $SYSLOG_PID 2>/dev/null

idevicecrashreport -e "$BACKUP_DIR/system/crash_reports/" 2>/dev/null || echo "Crash reports unavailable"

# 5. Create backup summary
echo "📄 Creating backup summary..."
cat > "$BACKUP_DIR/BACKUP_README.txt" << EOF
iPhone Backup Created: $(date)
Device UDID: $UDID
iOS Version: $(ideviceinfo -s -k ProductVersion)
Device Name: $(ideviceinfo -s -k DeviceName)
Product Type: $(ideviceinfo -s -k ProductType)

BACKUP CONTENTS:
- device_info/: Complete device information and installed apps list
- photos/: Photos backup (if accessible via ifuse)
- apps/: List of installed applications
- system/: System logs and crash reports
- documents/: App documents (if accessible)

IMPORTANT NOTES:
1. Due to iOS security, full app data backup requires iTunes/Finder
2. For complete photo backup, ensure iCloud Photos sync or manual export
3. Messages and other personal data require iTunes encrypted backup
4. This backup focuses on device configuration and accessible data

RESTORATION NOTES:
- After MDM supervision, you'll need to manually restore:
  - Photos (from iCloud or manual backup)
  - Apps (re-download from App Store)
  - App data (from iCloud sync or iTunes backup)
  - Messages (from iTunes encrypted backup only)
EOF

echo "✅ Backup completed: $BACKUP_DIR"
echo ""
echo "⚠️  IMPORTANT: This backup has limitations due to iOS security."
echo "For complete backup, also do:"
echo "1. iTunes/Finder encrypted backup"
echo "2. iCloud Photos sync"
echo "3. Export important documents manually"
echo ""
ls -la "$BACKUP_DIR"