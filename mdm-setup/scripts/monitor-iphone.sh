#!/bin/bash

echo "Monitoring for iPhone connection..."
echo "Please connect your iPhone and unlock it."
echo "Press Ctrl+C to stop monitoring."
echo ""

while true; do
    DEVICES=$(idevice_id -l)
    USB_INFO=$(system_profiler SPUSBDataType | grep -A 3 -B 1 "iPhone")
    
    if [ -n "$DEVICES" ]; then
        echo "✅ iPhone detected!"
        echo "Device UDIDs:"
        echo "$DEVICES"
        echo ""
        echo "USB Information:"
        echo "$USB_INFO"
        echo ""
        echo "Testing device info..."
        ideviceinfo -s -k DeviceName -k ProductVersion -k ProductType
        break
    else
        echo "⏳ No iPhone detected... checking again in 3 seconds"
        if [ -n "$USB_INFO" ]; then
            echo "📱 iPhone visible in USB but not paired/trusted:"
            echo "$USB_INFO"
        fi
    fi
    
    sleep 3
done